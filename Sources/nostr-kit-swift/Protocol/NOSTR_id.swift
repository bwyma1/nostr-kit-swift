import RAW
import RAW_dh25519

/// The 32-byte SHA-256 digest that uniquely identifies a signed event.
///
/// An event's `id` is the SHA-256 hash of its serialized fields. It is used to
/// index references to other events and to prevent accidental duplicates.
@RAW_staticbuff(bytes: 32)
public struct NOSTR_id:Sendable, Hashable, Comparable, RAW_convertible, RAW_accessible, NOSTR_tag_value {}
