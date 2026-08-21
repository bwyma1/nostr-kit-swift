import RAW
import RAW_base64

/// A 1-byte, big-endian unsigned integer used as a fixed-width wire field.
@RAW_staticbuff_fixedwidthinteger_type<UInt8>(bigEndian: true)
@RAW_staticbuff(bytes: 1)
public struct Bytes1:Sendable, Hashable, Equatable, Comparable {
	public var debugDescription:String {
		return "\(String(RAW_base64.encode(self)))"
	}
}

/// A 2-byte, big-endian unsigned integer used as a fixed-width wire field.
@RAW_staticbuff_fixedwidthinteger_type<UInt16>(bigEndian: true)
@RAW_staticbuff(bytes: 2)
public struct Bytes2:Sendable, Hashable, Equatable, Comparable {
	public var debugDescription:String {
		return "\(String(RAW_base64.encode(self)))"
	}
}

/// A 4-byte, big-endian unsigned integer used as a fixed-width wire field.
@RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian: true)
@RAW_staticbuff(bytes: 4)
public struct Bytes4:Sendable, Hashable, Equatable, Comparable {
	public var debugDescription:String {
		return "\(String(RAW_base64.encode(self)))"
	}
}
