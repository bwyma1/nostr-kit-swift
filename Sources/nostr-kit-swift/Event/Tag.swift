#if os(Linux)
import Glibc
#else
import Darwin
#endif
import RAW
import RAW_dh25519

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
		var dataCount = count - MemoryLayout<NOSTR_tag_name>.size - MemoryLayout<Bytes1>.size
		
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

/// Basic string value initializer.
extension EventTag {
	public init(tagName:String, tagValues:[String]) {
		NOSTR_tag_index_field = tagName.data(using: .utf8)!.withUnsafeBytes { ptr in
			NOSTR_tag_name(RAW_staticbuff: ptr.baseAddress!)
		}
		NOSTR_tag_values = tagValues.map { NOSTR_tag_generic_value(stringLiteral: $0) }
	}
}

/// Initializing an event tag for referencing other `NOSTR_event_signed`
/// - `Event ID` - 	ID of the referenced event.
/// - `Relay URL` - 	Hint where to find this event.
/// - `Marker` - 		Relationship type (root, reply, mention, ...)
extension EventTag {
	public init(eventID:NOSTR_id, relayUrl:String? = nil, marker:String? = nil) {
		let tagName = "e"
		NOSTR_tag_index_field = tagName.data(using: .utf8)!.withUnsafeBytes { ptr in
			NOSTR_tag_name(RAW_staticbuff: ptr.baseAddress!)
		}
		guard relayUrl != nil || marker != nil else {
			NOSTR_tag_values = [eventID]
			return
		}
		guard let relayUrl = relayUrl else {
			NOSTR_tag_values = [eventID, NOSTR_tag_generic_value(stringLiteral: marker!)]
			return
		}
		guard let marker = marker else {
			NOSTR_tag_values = [eventID, NOSTR_tag_generic_value(stringLiteral: relayUrl)]
			return
		}
		NOSTR_tag_values = [eventID, NOSTR_tag_generic_value(stringLiteral: relayUrl), NOSTR_tag_generic_value(stringLiteral: marker)]
	}
}

extension PublicKey: NOSTR_tag_value {}

/// Initializing an event tag for referencing other user/author.
/// - `User` - 		Public Key of the user being referenced
/// - `Relay URL` - 	Hint where to find this user.
extension EventTag {
	public init(user:PublicKey, relayUrl:String? = nil) {
		let tagName = "p"
		NOSTR_tag_index_field = tagName.data(using: .utf8)!.withUnsafeBytes { ptr in
			NOSTR_tag_name(RAW_staticbuff: ptr.baseAddress!)
		}
		guard let relayUrl = relayUrl else {
			NOSTR_tag_values = [user]
			return
		}
		NOSTR_tag_values = [user, NOSTR_tag_generic_value(stringLiteral: relayUrl)]
	}
}
