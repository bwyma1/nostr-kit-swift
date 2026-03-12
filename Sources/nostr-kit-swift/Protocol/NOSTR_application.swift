import RAW

@RAW_staticbuff(bytes: 2)
@RAW_staticbuff_fixedwidthinteger_type<UInt16>(bigEndian: true)
/// The application of `NOSTR_event`
/// A 2-byte event identifier which is a level above kind.
///
/// The relay should check the application first, then the kind to
/// determine what action should be taken on the incoming event.
public struct NOSTR_application: Sendable, Hashable, Comparable, RAW_convertible {
	public init(_ application: UInt8) {
		self = NOSTR_application(RAW_native: UInt16(application))
	}
	public init(_ application: UInt16) {
		self = NOSTR_application(RAW_native: application)
	}
}
