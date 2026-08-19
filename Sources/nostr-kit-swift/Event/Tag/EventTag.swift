#if os(Linux)
import Glibc
#else
import Darwin
#endif
import RAW
import RAW_dh25519

/// Generic tag needed for decoding tags.
public struct EventTag: Sendable, Hashable, NOSTR_tag {
	
	public typealias tagValueType = NOSTR_tag_generic_value
	
	public var indexField: NOSTR_tag_name
	
	public var value: tagValueType
	
	public init(value: tagValueType) {
		self.indexField = NOSTR_tag_name(string: "")
		self.value = value
	}
	
	public init(indexField:NOSTR_tag_name, value: tagValueType) {
		self.indexField = indexField
		self.value = value
	}
}

extension EventTag: RAW_convertible {
	public init?(RAW_decode inputPtr:consuming UnsafeRawPointer, count: RAW.size_t) {
		var dataCount = count
		guard dataCount >= MemoryLayout<NOSTR_tag_name>.size else { return nil }
		
		self.indexField = NOSTR_tag_name(RAW_staticbuff_seeking: &inputPtr)
		dataCount -= MemoryLayout<NOSTR_tag_name>.size
		
		guard dataCount >= MemoryLayout<Bytes4>.size else { return nil }
		dataCount -= MemoryLayout<Bytes4>.size
		let length = Int(Bytes4(RAW_staticbuff_seeking: &inputPtr).RAW_native())
		guard dataCount >= length else { return nil }
		dataCount -= length
		self.value = NOSTR_tag_generic_value(RAW_decode: inputPtr, count: length)
		guard dataCount == 0 else { return nil }
	}
	
	public func RAW_encode(count: inout RAW.size_t) {
		count += MemoryLayout<NOSTR_tag_name>.size + MemoryLayout<Bytes4>.size
		value.RAW_encode(count: &count)
	}
	
	public func RAW_encode(dest: UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
		var dest = indexField.RAW_encode(dest: dest)
		
		var tagValueLength = 0; value.RAW_encode(count: &tagValueLength)
		let tagValueLengthBytes = Bytes4(RAW_native: UInt32(tagValueLength))
		dest = tagValueLengthBytes.RAW_encode(dest: dest)
		dest = value.RAW_encode(dest: dest)
		
		return dest
	}
}
