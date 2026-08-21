import RAW

/// The kind of a `NOSTR_event`.
///
/// The kind is application-specific and determines how the event's content is
/// interpreted. It is a 4-byte, big-endian value.
///
/// Relevant kinds:
/// - Kind 0: User profile event.
/// - Kind 5: Deletion event.
/// - Kinds 0–9999: Regular Nostr-specific immutable events.
/// - Kinds 10000–19999: Replaceable events, unique per `(publicKey, kind)`.
/// - Kinds 20000–29999: Ephemeral events. Should not be stored or replayed.
/// - Kinds 30000–39999: Parameterized replaceable events, unique per `(publicKey, kind, d-tag value)`.
@RAW_staticbuff(bytes: 4)
@RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian: true)
public struct NOSTR_kind: Sendable, Hashable, Comparable, RAW_convertible {
	/// Creates a kind from a `UInt8`.
	public init(_ kind: UInt8) {
		self = NOSTR_kind(RAW_native: UInt32(kind))
	}
	/// Creates a kind from a `UInt16`.
	public init(_ kind: UInt16) {
		self = NOSTR_kind(RAW_native: UInt32(kind))
	}
	/// Creates a kind from a `UInt32`.
	public init(_ kind: UInt32) {
		self = NOSTR_kind(RAW_native: kind)
	}
}
