import RAW
import Foundation

/// The creation time of a `NOSTR_event`, represented as a Unix timestamp.
///
/// The date is stored as an 8-byte, big-endian Unix timestamp (seconds since the
/// Unix epoch).
@RAW_staticbuff(bytes:8)
@RAW_staticbuff_fixedwidthinteger_type<UInt64>(bigEndian: true)
public struct NOSTR_date: Sendable, Hashable, Comparable, NOSTR_tag_value {
	/// Creates a date from a `Foundation.Date`.
	public init(date: Foundation.Date) {
		self = NOSTR_date(RAW_native: UInt64(date.timeIntervalSince1970))
	}
	/// Creates a date from a Unix timestamp in seconds.
	public init(_ date:UInt64) {
		self = NOSTR_date(RAW_native: date)
	}
	/// The Unix timestamp in seconds.
	public func currentTime() -> UInt64 {
		return self.RAW_native()
	}
	/// The date as a `Foundation.Date`.
	public func currentDate() -> Foundation.Date {
		Foundation.Date(timeIntervalSince1970: TimeInterval(self.RAW_native()))
	}
}
