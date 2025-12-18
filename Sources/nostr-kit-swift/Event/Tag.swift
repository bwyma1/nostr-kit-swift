#if os(Linux)
import Glibc
#else
import Darwin
#endif
import RAW

public struct EventTag: NOSTR_tag {
	
	public var NOSTR_tag_index_field: NOSTR_tag_name
	
	// Use 2 bytes for the length of each tag value
	public var NOSTR_tag_values: [any NOSTR_tag_value]
	
	public init(NOSTR_tag_index_field: NOSTR_tag_name, NOSTR_tag_values: [any NOSTR_tag_value]) throws {
		self.NOSTR_tag_index_field = NOSTR_tag_index_field
		self.NOSTR_tag_values = NOSTR_tag_values
	}
	
	public init?(RAW_decode inputPtr:consuming UnsafeRawPointer, count: RAW.size_t) {
		guard count >= MemoryLayout<NOSTR_tag_name>.size else { return nil }

		let tagName = NOSTR_tag_name(RAW_staticbuff_seeking: &inputPtr)
		let tagValueCount = Bytes1(RAW_staticbuff_seeking: &inputPtr).RAW_native()
		var dataCount = count - MemoryLayout<NOSTR_tag_name>.size
		
		var values: [any NOSTR_tag_value] = []
		for _ in 0..<Int(tagValueCount) {
			// Read length of next tag value
			guard dataCount >= MemoryLayout<Bytes2>.size else { return nil }
			dataCount -= MemoryLayout<Bytes2>.size
			let length = Int(Bytes2(RAW_staticbuff_seeking: &inputPtr).RAW_native())
			// Read the tag value
			guard dataCount >= length else { return nil }
			dataCount -= length
			let value = NOSTR_tag_generic_value(RAW_decode: inputPtr, count: length)
			inputPtr = inputPtr.advanced(by: length)
			values.append(value)
		}
		NOSTR_tag_index_field = tagName
		NOSTR_tag_values = values
	}
	
	public func RAW_encode(count: inout RAW.size_t) {
		// Add 1 for the number of tag values
		count += MemoryLayout<NOSTR_tag_name>.size + MemoryLayout<Bytes1>.size
		for tagValue in NOSTR_tag_values {
			// Add 2 for the length of the tag value
			count += MemoryLayout<Bytes2>.size
			tagValue.RAW_encode(count: &count)
		}
	}
	
	public func RAW_encode(dest: UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
		var dest = NOSTR_tag_index_field.RAW_encode(dest: dest)
		// Encode the number of tag values
		let tagValueCount = Bytes1(RAW_native: UInt8(NOSTR_tag_values.count))
		dest = tagValueCount.RAW_encode(dest: dest)
		
		for tagValue in NOSTR_tag_values {
			// Encode the length of the tag value
			var tagValueLength = 0; tagValue.RAW_encode(count: &tagValueLength)
			let tagValueLengthBytes = Bytes2(RAW_native: UInt16(tagValueLength))
			dest = tagValueLengthBytes.RAW_encode(dest: dest)
			
			// Encode the tag value itself
			dest = tagValue.RAW_encode(dest: dest)
		}
		return dest
	}
}


