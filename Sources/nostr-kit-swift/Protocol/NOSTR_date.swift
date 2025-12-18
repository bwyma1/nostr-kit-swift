import RAW
import Foundation

@RAW_staticbuff(bytes:8)
@RAW_staticbuff_fixedwidthinteger_type<UInt64>(bigEndian: true)
/// The time signature at which the `NOSTR_event` was created.
/// The date is represented as a unix timestamp.
public struct NOSTR_date: Sendable, Comparable, RAW_convertible {
	public init(date: Foundation.Date) {
		self = NOSTR_date(RAW_native: UInt64(date.timeIntervalSince1970))
	}
	init(_ date:UInt64) {
		self = NOSTR_date(RAW_native: date)
	}
	func currentTime() -> UInt64 {
		return self.RAW_native()
	}
}
