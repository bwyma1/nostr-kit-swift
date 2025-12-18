import RAW

@RAW_staticbuff(bytes: 2)
@RAW_staticbuff_fixedwidthinteger_type<UInt16>(bigEndian: true)
/// The kind of `NOSTR_event`
/// Application specific. Used to determine how to interpret the meaning of each event.
public struct NOSTR_kind: Sendable, Comparable, RAW_convertible {
	init(_ kind: UInt8) {
		self = NOSTR_kind(RAW_native: UInt16(kind))
	}
	init(_ kind: UInt16) {
		self = NOSTR_kind(RAW_native: kind)
	}
}
