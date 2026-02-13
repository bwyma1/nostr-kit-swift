import Foundation
import RAW

@RAW_staticbuff(bytes:4)
@RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian:true)
internal struct EncodedUInt32:Sendable, ExpressibleByIntegerLiteral {}

@RAW_staticbuff(bytes:8)
@RAW_staticbuff_fixedwidthinteger_type<UInt64>(bigEndian:true)
internal struct EncodedUInt64:Sendable, ExpressibleByIntegerLiteral {}

@RAW_staticbuff(bytes:16)
@RAW_staticbuff_fixedwidthinteger_type<UInt128>(bigEndian:true)
internal struct EncodedUInt128:Sendable, ExpressibleByIntegerLiteral {}

@RAW_staticbuff(bytes: 1)
@RAW_staticbuff_fixedwidthinteger_type<UInt8>(bigEndian: true)
public struct EncodedBool: Sendable, Equatable, Hashable, Comparable, RAW_convertible {
	public var bool:Bool {
		self.RAW_native() != 0
	}
	
	public init(_ bool:Bool) {
		self = bool ? EncodedBool(RAW_native: 1) : EncodedBool(RAW_native: 0)
	}
}

@RAW_convertible_string_type<UTF8>(backing:RAW_byte.self)
public struct EncodedString:Sendable, Equatable, Hashable, Comparable, ExpressibleByStringLiteral, CustomDebugStringConvertible {
	public var debugDescription:String {
		return String(self)
	}
}
