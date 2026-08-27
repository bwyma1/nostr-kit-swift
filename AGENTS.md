# AGENTS.md

Agent-facing guide for **nostr-kit-swift**.

## What this project is

A Swift library for the **Nostr** protocol, built on the [`rawdog`](https://github.com/tannerdsilva/rawdog) family of low-level byte/encoding packages (`RAW`, `RAW_sha256`, `RAW_ed25519`, `RAW_dh25519`, `RAW_base64`). It provides typed data structures for events, filters, and wire messages, plus a set of **Swift macros** (`@NostrContent`, `@NostrTag`) that auto-generate `RAW_convertible` encoding/decoding conformances.

> **Important:** This is NOT the standard JSON NOSTR NIP-01 serialization. It uses a custom **binary RAW encoding**. Event ids are a custom sha256 over serialized RAW fields — not the standard `sha256(0x00 || pubkey || created_at || kind || tags_json || content)`. Do not "fix" this to match the spec unless explicitly asked; changing the id/hash computation is a breaking wire-format change.

## Module / target layout

`Package.swift` defines three targets (Swift tools version 6.2, macOS 15+):

- **`ContentMacros`** (macro target) — `Sources/ContentMacros/`
  - `Plugin.swift` — the `@main` compiler plugin registering `NostrContent` and `NostrTag`.
  - `NostrContent.swift` — `@NostrContent` macro: generates `RAW_convertible` (decode + encode + count) plus two `init`s (native-typed + `Encoded*`-typed). Handles nesting through dictionaries/arrays/optionals via recursive `resolve*` string builders.
  - `NostrTag.swift` — `@NostrTag(name:valueType:)` macro (member + extension): generates `RAW_convertible` for tag structs. When `name:` is provided it generates the `indexField` stored property and a decode-time name check; when `valueType:` is provided it generates the `value` stored property and an `init(value:)`. The decode path routes the value through a protocol-constrained generic helper (`_decodeTagValue`), so it is always treated as failable regardless of whether the value type's concrete `RAW_decode` can return nil — this replaced the old `safeDecode:` flag. Rejects empty or >8-byte (UTF-8) names at compile time. Members already declared in the struct are left alone.
- **`nostr-kit-swift`** (library) — `Sources/nostr-kit-swift/`
  - `Protocol/` — core scalar types: `NOSTR_id`, `NOSTR_sig`, `NOSTR_kind`, `NOSTR_application`, `NOSTR_date`, `NOSTR_event` (the `NOSTR_event_unsigned` protocol + `NOSTR_event_signed`), and `TAG/` (`NOSTR_tag`, `NOSTR_tag_name`, `NOSTR_tag_generic_value`).
  - `Event/` — `UnsignedEvent` (concrete event struct + `NOSTR_tags`), `ByteStructs.swift` (`Bytes1/2/4`), `ContentStructs.swift` (the `Encoded` namespace: `Encoded.Bool/UInt16/.../String/Date/Data` and `Encoded.Data`), `Tag/` (`EventTag`, `NostrTags` helpers, `ValueInitializers`).
  - `Message/` — `NOSTR_message` enum + per-type message structs (`REQ`, `EVENT`, `EOSE`, `CLOSE`, `NOTICE`, `OK`).
  - `Filter/` — `Filter` (list + time-range + limit predicates) and `apply(to:)` matching.
  - `Macros.swift` — public macro declarations (attached `member` + `extension`).
  - `RAWExtension.swift` — `RAW_access` / `RAW_access_mutating` helpers for reading/modifying a value's encoded bytes.
- **`nostr-kit-swiftTests`** — `Tests/nostr-kit-swiftTests/` (`NostrTests.swift`, `MacroTests.swift`).

## Build / test / run

```sh
swift build          # builds the library + macros
swift test           # runs the full suite (Swift Testing framework)
```

- Requires macOS 15+; a local checkout of `rawdog` is pinned by commit `1c4966c7…` (network fetch on first build).
- No custom `build.sh`, no code-signing.

## Critical domain rules — DO NOT break these

- **Binary wire format is defined by the RAW macros and the `RAW_encode`/`RAW_decode` pairs.** Any change to the order of fields written in `RAW_encode(count:)`/`RAW_encode(dest:)` or read in `RAW_decode` changes the on-the-wire/on-disk format. Keep encode and decode symmetric, and preserve field order.
- **Event `id` is the sha256 of the serialized fields** (pubkey → date → each tag's bytes → application → kind → content). The id must be computed with the exact field order and the exact per-tag encoding (no length prefix on tags for the *hash*, but a `Bytes4` length prefix in the *event* encoding — see `UnsignedEvent` vs the `NOSTR_event_unsigned` id computation). Do not "improve" the duplication here without preserving byte-for-byte identical output.
- **`UnsignedEvent.RAW_decode`** reads, in order: `id`, `publicKey`, `date`, then a `Bytes2` tag count, then per-tag (`Bytes4` length + tag bytes), then `application`, `kind`, `content`. Bounds are checked against a running `dataCount` that must be decremented as bytes are consumed.
- **`Filter.RAW_decode`** order: `ids`, `authors`, `applications`, `kinds`, `tags`, then presence flags + values for `since`/`until`/`limit`. `dataCount` must track remaining bytes monotonically (decrement as you consume) — resetting it per-section can over-count and allow out-of-bounds reads.
- **Tag equality is byte-level, not type-sensitive.** `NOSTR_tags.==` compares tags with `isEqual(to:)` (a `memcmp`), and `NOSTR_tags.hash(into:)` hashes the RAW bytes via `hasher.combine(bytes:)` so hashing stays consistent with equality (a `StringTag` and an `EventTag` wrapping identical bytes compare equal AND hash equal). Do not switch this to `AnyHashable`/type-based or `hashValue`-based equality/hashing — it breaks `encodeDecodeEvent` and the Hashable contract.
- **`RAW_access` / `RAW_access_mutating`** are typed `throws(E)`. `withUnsafeTemporaryAllocation` rethrows as `any Error`, so errors must be re-cast to `E` (`throw error as! E`); the plain `try` does NOT compile and `try!` crashes the process when the body throws. Do not reintroduce `try!`. A `RAW_access_mutating` mutation that leaves the value in an undecodable state now throws `RAWAccessError.invalidMutatedState` instead of calling `fatalError`.
- **Macro-generated decode** appends `guard dataCount == 0 else { return nil }` after all fields. `@NostrTag` encode always writes a `Bytes4` value-length prefix; `@NostrContent` writes a `Bytes4` length prefix only for `Encoded.String`/`Encoded.Data` and unknown types, and relies on the macro's `nostrContentTypes` list for fixed-width types. The encoded scalar types live as nested types under the `Encoded` namespace (`Encoded.Bool`, `Encoded.Int128`, ...) — do NOT reintroduce the old top-level `Encoded*` names.

## Conventions

- **Testing: Swift Testing framework, NEVER XCTest.** Use `import Testing`, `@Test`, `#expect`, `@Suite`. The suites are marked `.serialized`. The user strongly prefers this — do not introduce XCTest.
- Tests use `@testable import nostr_kit_swift` and access `@testable`-visible members (e.g. the internal `type` field on message structs).
- **Serialization:** all wire types are `RAW_convertible`; encoding uses `RAW_encode(count:)` for sizing and `RAW_encode(dest:)` for writing. The project idiom is `var len = 0; value.RAW_encode(count: &len)` followed by an `UnsafeMutableBufferPointer` allocation.
- **Concurrency:** structs are `Sendable`, `Hashable`. No actors, no `ServiceGroup`.
- **Naming:** `NOSTR_*` prefix for protocol/wire types; `Encoded*` for encoded content scalars; `Bytes1/2/4` for fixed-width wire integers (big-endian).
- Formatting uses tabs (not spaces); files are tab-indented.