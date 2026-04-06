import Foundation
import RAW

extension RAW_byte: NOSTR_tag_value {}

@RAW_staticbuff(bytes:2)
@RAW_staticbuff_fixedwidthinteger_type<UInt16>(bigEndian:true)
public struct EncodedUInt16:Sendable, ExpressibleByIntegerLiteral, NOSTR_tag_value {}

@RAW_staticbuff(bytes:4)
@RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian:true)
public struct EncodedUInt32:Sendable, ExpressibleByIntegerLiteral, NOSTR_tag_value {}

@RAW_staticbuff(bytes:8)
@RAW_staticbuff_fixedwidthinteger_type<UInt64>(bigEndian:true)
public struct EncodedUInt64:Sendable, ExpressibleByIntegerLiteral, NOSTR_tag_value {}

@RAW_staticbuff(bytes:16)
@RAW_staticbuff_fixedwidthinteger_type<UInt128>(bigEndian:true)
public struct EncodedUInt128:Sendable, ExpressibleByIntegerLiteral, NOSTR_tag_value {}

@RAW_staticbuff(bytes:2)
@RAW_staticbuff_fixedwidthinteger_type<Int16>(bigEndian:true)
public struct EncodedInt16:Sendable, ExpressibleByIntegerLiteral, NOSTR_tag_value {}

@RAW_staticbuff(bytes:4)
@RAW_staticbuff_fixedwidthinteger_type<Int32>(bigEndian:true)
public struct EncodedInt32:Sendable, ExpressibleByIntegerLiteral, NOSTR_tag_value {}

@RAW_staticbuff(bytes:8)
@RAW_staticbuff_fixedwidthinteger_type<Int64>(bigEndian:true)
public struct EncodedInt64:Sendable, ExpressibleByIntegerLiteral, NOSTR_tag_value {}

@RAW_staticbuff(bytes:16)
@RAW_staticbuff_fixedwidthinteger_type<Int128>(bigEndian:true)
public struct EncodedInt128:Sendable, ExpressibleByIntegerLiteral, NOSTR_tag_value {}

@RAW_staticbuff(bytes: 4)
@RAW_staticbuff_binaryfloatingpoint_type<Float>
public struct EncodedFloat:Sendable, ExpressibleByFloatLiteral, NOSTR_tag_value {}

@RAW_staticbuff(bytes: 1)
@RAW_staticbuff_fixedwidthinteger_type<UInt8>(bigEndian: true)
public struct EncodedBool: Sendable, NOSTR_tag_value {
	public var bool:Bool {
		self.RAW_native() != 0
	}
	
	public init(_ bool:Bool) {
		self = bool ? EncodedBool(RAW_native: 1) : EncodedBool(RAW_native: 0)
	}
}

@RAW_convertible_string_type<UTF8>(backing:RAW_byte.self)
public struct EncodedString:Sendable, Equatable, Hashable, Comparable, ExpressibleByStringLiteral, CustomDebugStringConvertible, NOSTR_tag_value {
	public var debugDescription:String {
		return String(self)
	}
}
