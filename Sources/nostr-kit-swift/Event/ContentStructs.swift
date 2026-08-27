import Foundation
import RAW

extension RAW_byte: NOSTR_tag_value {}

/// A namespace grouping the raw, wire-encodable scalar types used as event
/// content and tag values.
///
/// Each nested type is the encoded (on-the-wire) representation of a Swift
/// native value: integers are stored as fixed-width, big-endian bytes,
/// floating-point values store their IEEE bit pattern, booleans store a single
/// byte, and strings/dates/data store their payload bytes.
public enum Encoded {
	/// Internal aliases that feed rawdog's macros a single-identifier backing type.
	///
	/// The macros copy their generic argument verbatim into generated members, and
	/// their type lister only picks up a plain identifier — a qualified name like
	/// `Swift.UInt16` collapses to just `Swift` in the expansion. These unqualified
	/// aliases (which refer to the standard library types) avoid both that mangling
	/// and the shadowing by these nested types themselves. They must be public
	/// because the macro-generated members that reference them are `public`.
	public typealias RawUInt8 = Swift.UInt8
	public typealias RawUInt16 = Swift.UInt16
	public typealias RawUInt32 = Swift.UInt32
	public typealias RawUInt64 = Swift.UInt64
	public typealias RawUInt128 = Swift.UInt128
	public typealias RawInt16 = Swift.Int16
	public typealias RawInt32 = Swift.Int32
	public typealias RawInt64 = Swift.Int64
	public typealias RawInt128 = Swift.Int128

	/// A 2-byte, big-endian unsigned integer usable as an event content or tag value.
	@RAW_staticbuff(bytes:2)
	@RAW_staticbuff_fixedwidthinteger_type<RawUInt16>(bigEndian:true)
	public struct UInt16:Sendable, ExpressibleByIntegerLiteral, NOSTR_tag_value {
		/// Resolves the macro-generated `RAW_compare` return type to the standard
		/// library `Int32` (shadowed inside this namespace by `Encoded.Int32`).
		public typealias Int32 = Swift.Int32
	}

	/// A 4-byte, big-endian unsigned integer usable as an event content or tag value.
	@RAW_staticbuff(bytes:4)
	@RAW_staticbuff_fixedwidthinteger_type<RawUInt32>(bigEndian:true)
	public struct UInt32:Sendable, ExpressibleByIntegerLiteral, NOSTR_tag_value {
		/// Resolves the macro-generated `RAW_compare` return type to the standard
		/// library `Int32` (shadowed inside this namespace by `Encoded.Int32`).
		public typealias Int32 = Swift.Int32
	}

	/// An 8-byte, big-endian unsigned integer usable as an event content or tag value.
	@RAW_staticbuff(bytes:8)
	@RAW_staticbuff_fixedwidthinteger_type<RawUInt64>(bigEndian:true)
	public struct UInt64:Sendable, ExpressibleByIntegerLiteral, NOSTR_tag_value {
		/// Resolves the macro-generated `RAW_compare` return type to the standard
		/// library `Int32` (shadowed inside this namespace by `Encoded.Int32`).
		public typealias Int32 = Swift.Int32
	}

	/// A 16-byte, big-endian unsigned integer usable as an event content or tag value.
	@RAW_staticbuff(bytes:16)
	@RAW_staticbuff_fixedwidthinteger_type<RawUInt128>(bigEndian:true)
	public struct UInt128:Sendable, ExpressibleByIntegerLiteral, NOSTR_tag_value {
		/// Resolves the macro-generated `RAW_compare` return type to the standard
		/// library `Int32` (shadowed inside this namespace by `Encoded.Int32`).
		public typealias Int32 = Swift.Int32
	}

	/// A 2-byte, big-endian signed integer usable as an event content or tag value.
	@RAW_staticbuff(bytes:2)
	@RAW_staticbuff_fixedwidthinteger_type<RawInt16>(bigEndian:true)
	public struct Int16:Sendable, ExpressibleByIntegerLiteral, NOSTR_tag_value {
		/// Resolves the macro-generated `RAW_compare` return type to the standard
		/// library `Int32` (shadowed inside this namespace by `Encoded.Int32`).
		public typealias Int32 = Swift.Int32
	}

	/// A 4-byte, big-endian signed integer usable as an event content or tag value.
	@RAW_staticbuff(bytes:4)
	@RAW_staticbuff_fixedwidthinteger_type<RawInt32>(bigEndian:true)
	public struct Int32:Sendable, ExpressibleByIntegerLiteral, NOSTR_tag_value {
		/// Resolves the macro-generated `RAW_compare` return type to the standard
		/// library `Int32` (shadowed inside this namespace by `Encoded.Int32`).
		public typealias Int32 = Swift.Int32
	}

	/// An 8-byte, big-endian signed integer usable as an event content or tag value.
	@RAW_staticbuff(bytes:8)
	@RAW_staticbuff_fixedwidthinteger_type<RawInt64>(bigEndian:true)
	public struct Int64:Sendable, ExpressibleByIntegerLiteral, NOSTR_tag_value {
		/// Resolves the macro-generated `RAW_compare` return type to the standard
		/// library `Int32` (shadowed inside this namespace by `Encoded.Int32`).
		public typealias Int32 = Swift.Int32
	}

	/// A 16-byte, big-endian signed integer usable as an event content or tag value.
	@RAW_staticbuff(bytes:16)
	@RAW_staticbuff_fixedwidthinteger_type<RawInt128>(bigEndian:true)
	public struct Int128:Sendable, ExpressibleByIntegerLiteral, NOSTR_tag_value {
		/// Resolves the macro-generated `RAW_compare` return type to the standard
		/// library `Int32` (shadowed inside this namespace by `Encoded.Int32`).
		public typealias Int32 = Swift.Int32
	}

	/// A 4-byte, big-endian binary floating-point value usable as an event content or tag value.
	@RAW_staticbuff(bytes: 4)
	public struct Float: Sendable, ExpressibleByFloatLiteral, RAW_encoded_binaryfloatingpoint, NOSTR_tag_value {
		/// Resolves the macro-generated `RAW_compare` return type to the standard
		/// library `Int32` (shadowed inside this namespace by `Encoded.Int32`).
		public typealias Int32 = Swift.Int32
		/// The stored native floating-point value.
		public func RAW_native() -> Swift.Float {
			#if DEBUG
			assert(MemoryLayout<Self>.size == MemoryLayout<RAW_staticbuff_storetype>.size, "static buffer type size mismatch. this is a misuse of the macro")
			assert(MemoryLayout<Swift.Float>.size == MemoryLayout<RAW_staticbuff_storetype>.size, "static buffer type size mismatch. this is a misuse of the macro")
			#endif
			return withUnsafePointer(to: self) { selfPtr in
				let bitPattern = UnsafeRawPointer(selfPtr).loadUnaligned(as: Swift.UInt32.self)
				return Swift.Float(bitPattern: bitPattern)
			}
		}

		/// Creates a floating-point value from its native Swift representation.
		public init(RAW_native native: Swift.Float) {
			#if DEBUG
			assert(MemoryLayout<RAW_native_type>.size == MemoryLayout<RAW_staticbuff_storetype>.size, "static buffer type size mismatch. this is a misuse of the macro")
			assert(MemoryLayout<Swift.Float>.size == MemoryLayout<RAW_staticbuff_storetype>.size, "static buffer type size mismatch. this is a misuse of the macro")
			#endif
			var enc = native.bitPattern
			self.init(RAW_staticbuff: &enc)
		}

		/// Compares two raw byte buffers as native floating-point values.
		public static func RAW_compare(lhs_data: UnsafeRawPointer, rhs_data: UnsafeRawPointer) -> Int32 {
			let lhs = Swift.Float(bitPattern: lhs_data.loadUnaligned(as: Swift.UInt32.self))
			let rhs = Swift.Float(bitPattern: rhs_data.loadUnaligned(as: Swift.UInt32.self))
			if lhs < rhs {
				return -1
			} else if lhs > rhs {
				return 1
			} else {
				return 0
			}
		}
	}

	/// A 1-byte boolean usable as an event content or tag value.
	@RAW_staticbuff(bytes: 1)
	@RAW_staticbuff_fixedwidthinteger_type<RawUInt8>(bigEndian: true)
	public struct Bool: Sendable, NOSTR_tag_value {
		/// Resolves the macro-generated `RAW_compare` return type to the standard
		/// library `Int32` (shadowed inside this namespace by `Encoded.Int32`).
		public typealias Int32 = Swift.Int32
		/// The boolean value represented by the encoded byte.
		public var bool: Swift.Bool {
			self.RAW_native() != 0
		}

		/// Creates a boolean value from a Swift `Bool`.
		public init(_ bool: Swift.Bool) {
			self = bool ? Bool(RAW_native: 1) : Bool(RAW_native: 0)
		}
	}

	/// A UTF-8 string usable as an event content or tag value.
	@RAW_convertible_string_type<UTF8>(backing: RAW_byte.self)
	public struct String: Sendable, Equatable, Hashable, Comparable, ExpressibleByStringLiteral, CustomDebugStringConvertible, NOSTR_tag_value {
		/// Resolves the macro-generated `init(_: consuming String.UnicodeScalarView)`
		/// so that `String` means the standard library type (this nested type is
		/// itself named `String`).
		public typealias UnicodeScalarView = Swift.String.UnicodeScalarView
		/// A textual representation of the string.
		public var debugDescription: Swift.String {
			return Swift.String(self)
		}
	}

	/// An 8-byte, big-endian Unix timestamp usable as an event content or tag value.
	@RAW_staticbuff(bytes:8)
	@RAW_staticbuff_fixedwidthinteger_type<RawUInt64>(bigEndian: true)
	public struct Date: Sendable, Hashable, Comparable, RAW_convertible, NOSTR_tag_value {
		/// Resolves the macro-generated `RAW_compare` return type to the standard
		/// library `Int32` (shadowed inside this namespace by `Encoded.Int32`).
		public typealias Int32 = Swift.Int32
		/// Creates a date value from a `Foundation.Date`.
		public init(date: Foundation.Date) {
			self = Date(RAW_native: Swift.UInt64(date.timeIntervalSince1970))
		}
		/// Creates a date value from a Unix timestamp in seconds.
		public init(_ date: Swift.UInt64) {
			self = Date(RAW_native: date)
		}
		/// The Unix timestamp in seconds.
		public func currentTime() -> Swift.UInt64 {
			return self.RAW_native()
		}
		/// The date as a `Foundation.Date`.
		public func currentDate() -> Foundation.Date {
			Foundation.Date(timeIntervalSince1970: TimeInterval(self.RAW_native()))
		}
	}

	/// An arbitrary-length block of bytes.
	public struct Data: Sendable, Hashable, Comparable, RAW_convertible {
		let data: Foundation.Data

		public static func < (lhs: Self, rhs: Self) -> Swift.Bool {
			lhs.data.lexicographicallyPrecedes(rhs.data)
		}

		/// Creates an encoded data value from the given `Foundation.Data`.
		public init(_ data: Foundation.Data) {
			self.data = data
		}

		public init?(RAW_decode inputPtr: consuming UnsafeRawPointer, count: RAW.size_t) {
			self.data = Foundation.Data(bytes: inputPtr, count: count)
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
}
