import Foundation
import RAW

extension RAW_byte: NOSTR_tag_value {}

/// A 2-byte, big-endian unsigned integer usable as an event content or tag value.
@RAW_staticbuff(bytes:2)
@RAW_staticbuff_fixedwidthinteger_type<UInt16>(bigEndian:true)
public struct EncodedUInt16:Sendable, ExpressibleByIntegerLiteral, NOSTR_tag_value {}

/// A 4-byte, big-endian unsigned integer usable as an event content or tag value.
@RAW_staticbuff(bytes:4)
@RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian:true)
public struct EncodedUInt32:Sendable, ExpressibleByIntegerLiteral, NOSTR_tag_value {}

/// An 8-byte, big-endian unsigned integer usable as an event content or tag value.
@RAW_staticbuff(bytes:8)
@RAW_staticbuff_fixedwidthinteger_type<UInt64>(bigEndian:true)
public struct EncodedUInt64:Sendable, ExpressibleByIntegerLiteral, NOSTR_tag_value {}

/// A 16-byte, big-endian unsigned integer usable as an event content or tag value.
@RAW_staticbuff(bytes:16)
@RAW_staticbuff_fixedwidthinteger_type<UInt128>(bigEndian:true)
public struct EncodedUInt128:Sendable, ExpressibleByIntegerLiteral, NOSTR_tag_value {}

/// A 2-byte, big-endian signed integer usable as an event content or tag value.
@RAW_staticbuff(bytes:2)
@RAW_staticbuff_fixedwidthinteger_type<Int16>(bigEndian:true)
public struct EncodedInt16:Sendable, ExpressibleByIntegerLiteral, NOSTR_tag_value {}

/// A 4-byte, big-endian signed integer usable as an event content or tag value.
@RAW_staticbuff(bytes:4)
@RAW_staticbuff_fixedwidthinteger_type<Int32>(bigEndian:true)
public struct EncodedInt32:Sendable, ExpressibleByIntegerLiteral, NOSTR_tag_value {}

/// An 8-byte, big-endian signed integer usable as an event content or tag value.
@RAW_staticbuff(bytes:8)
@RAW_staticbuff_fixedwidthinteger_type<Int64>(bigEndian:true)
public struct EncodedInt64:Sendable, ExpressibleByIntegerLiteral, NOSTR_tag_value {}

/// A 16-byte, big-endian signed integer usable as an event content or tag value.
@RAW_staticbuff(bytes:16)
@RAW_staticbuff_fixedwidthinteger_type<Int128>(bigEndian:true)
public struct EncodedInt128:Sendable, ExpressibleByIntegerLiteral, NOSTR_tag_value {}

/// A 4-byte, big-endian binary floating-point value usable as an event content or tag value.
@RAW_staticbuff(bytes: 4)
@RAW_staticbuff_binaryfloatingpoint_type<Float>
public struct EncodedFloat:Sendable, ExpressibleByFloatLiteral, NOSTR_tag_value {}

/// A 1-byte boolean usable as an event content or tag value.
@RAW_staticbuff(bytes: 1)
@RAW_staticbuff_fixedwidthinteger_type<UInt8>(bigEndian: true)
public struct EncodedBool: Sendable, NOSTR_tag_value {
	/// The boolean value represented by the encoded byte.
	public var bool:Bool {
		self.RAW_native() != 0
	}
	
	/// Creates a boolean value from a Swift `Bool`.
	public init(_ bool:Bool) {
		self = bool ? EncodedBool(RAW_native: 1) : EncodedBool(RAW_native: 0)
	}
}

/// A UTF-8 string usable as an event content or tag value.
@RAW_convertible_string_type<UTF8>(backing:RAW_byte.self)
public struct EncodedString:Sendable, Equatable, Hashable, Comparable, ExpressibleByStringLiteral, CustomDebugStringConvertible, NOSTR_tag_value {
	/// A textual representation of the string.
	public var debugDescription:String {
		return String(self)
	}
}

/// An 8-byte, big-endian Unix timestamp usable as an event content or tag value.
@RAW_staticbuff(bytes:8)
@RAW_staticbuff_fixedwidthinteger_type<UInt64>(bigEndian: true)
public struct EncodedDate: Sendable, Hashable, Comparable, RAW_convertible, NOSTR_tag_value {
	/// Creates a date value from a `Foundation.Date`.
	public init(date: Foundation.Date) {
		self = EncodedDate(RAW_native: UInt64(date.timeIntervalSince1970))
	}
	/// Creates a date value from a Unix timestamp in seconds.
	public init(_ date:UInt64) {
		self = EncodedDate(RAW_native: date)
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

/// An arbitrary-length block of bytes.
public struct EncodedData: Sendable, Hashable, Comparable, RAW_convertible {
	let data: Data
	
	public static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.data.lexicographicallyPrecedes(rhs.data)
	}
	
	/// Creates an encoded data value from the given `Data`.
	public init(_ data:Data) {
		self.data = data
	}
	
	
	public init?(RAW_decode inputPtr:consuming UnsafeRawPointer, count: RAW.size_t) {
		self.data = Data(bytes: inputPtr, count: count)
	}

	public func RAW_encode(count: inout RAW.size_t) {
		count += self.data.count
	}

	public func RAW_encode(dest: UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
		data.withUnsafeBytes { srcBuffer in
			guard let srcBase = srcBuffer.baseAddress else {
				return
			}
			dest.update(from: srcBase.assumingMemoryBound(to: UInt8.self), count: srcBuffer.count)
		}
		return dest.advanced(by: data.count)
	}
}
