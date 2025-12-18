import RAW
import RAW_base64

@RAW_staticbuff_fixedwidthinteger_type<UInt8>(bigEndian: true)
@RAW_staticbuff(bytes: 1)
internal struct Bytes1:Sendable, Hashable, Equatable, Comparable {
	public var debugDescription:String {
		return "\(String(RAW_base64.encode(self)))"
	}
}

@RAW_staticbuff_fixedwidthinteger_type<UInt16>(bigEndian: true)
@RAW_staticbuff(bytes: 2)
internal struct Bytes2:Sendable, Hashable, Equatable, Comparable {
	public var debugDescription:String {
		return "\(String(RAW_base64.encode(self)))"
	}
}

@RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian: true)
@RAW_staticbuff(bytes: 4)
internal struct Bytes4:Sendable, Hashable, Equatable, Comparable {
	public var debugDescription:String {
		return "\(String(RAW_base64.encode(self)))"
	}
}
