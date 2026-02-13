import RAW

@RAW_staticbuff(bytes: 2)
@RAW_staticbuff_fixedwidthinteger_type<UInt16>(bigEndian: true)
/// The kind of `NOSTR_event`
/// Application specific. Used to determine how to interpret the meaning of each event.
/// 
/// Relevent kinds:
/// - Kind 5: Deletion Event.
/// - Kind 0-9999: Special Nostr specific Immutable events.
/// - Kinds 10000-19999: Replaceable per the primary key (publickey, kind).
/// - Kinds 20000-29999: Ephemeral Events. Should not be stored. Should not be replayed.
/// - Kinds 30000-39999: Parameterized Replaceable Events. Replaceable per the primary key (publikey, kind, d-tagVal)
public struct NOSTR_kind: Sendable, Comparable, RAW_convertible {
	init(_ kind: UInt8) {
		self = NOSTR_kind(RAW_native: UInt16(kind))
	}
	init(_ kind: UInt16) {
		self = NOSTR_kind(RAW_native: kind)
	}
}
