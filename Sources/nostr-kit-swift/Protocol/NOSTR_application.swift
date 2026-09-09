import RAW

/// The application of a `NOSTR_event`.
///
/// A 2-byte, big-endian event identifier that sits one level above kind. A relay
/// should check the application first, then the kind, to determine what action
/// to take on an incoming event.
@RAW_staticbuff(bytes: 2)
@RAW_staticbuff_fixedwidthinteger_type<UInt16>(bigEndian: true)
public struct NOSTR_application: Sendable, Hashable, Comparable {
	/// Creates an application from a `UInt8`.
	public init(_ application: UInt8) {
		self = NOSTR_application(RAW_native: UInt16(application))
	}
	/// Creates an application from a `UInt16`.
	public init(_ application: UInt16) {
		self = NOSTR_application(RAW_native: application)
	}
}
