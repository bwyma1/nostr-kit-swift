# nostr-kit-swift

A Swift library for the Nostr protocol, built on the [rawdog](https://github.com/tannerdsilva/rawdog)
`RAW` encoding stack. It provides typed structures for events, filters, tags, and wire messages,
plus Swift macros (`@NostrContent`, `@NostrTag`) that generate `RAW_decodable`/`RAW_encodable`
conformances.

> **Wire format:** this library uses a custom binary RAW encoding — not the standard JSON NOSTR
> NIP-01 serialization. Event ids are the SHA-256 hash of the serialized RAW fields in the
> canonical order (public key, date, tags, application, kind, content).

## Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Modules](#modules)
- [Testing](#testing)

## Requirements

- macOS 15+
- Swift 6.2+

## Installation

Add the package to a Swift package manifest:

```swift
.package(url: "https://github.com/bwyma1/nostr-kit-swift", "0.0.0"..<"1.0.0")
```

## Usage

```swift
import nostr_kit_swift

// An unsigned event — its id is derived from the serialized fields.
let tag = StringTag(name: "e", value: "abcd")!
let event = try UnsignedEvent<StringContent>(
    publicKey: publicKey,
    tags: [tag],
    application: NOSTR_application(UInt16(1)),
    kind: NOSTR_kind(UInt32(1)),
    content: "hello"
)

// Signing and validation.
let signed = try event.sign(as: privateKey)
let signatureValid = signed.isValidSignature()

// Filtering.
let filter = Filter(kinds: [NOSTR_kind(UInt32(1))])
let matches = filter.apply(to: signed)
```

## Modules

- `nostr-kit-swift` — event, message, filter, and tag types.
- `ContentMacros` — the `@NostrContent` and `@NostrTag` macro implementations, used via the library.

## Testing

```sh
swift test
```
