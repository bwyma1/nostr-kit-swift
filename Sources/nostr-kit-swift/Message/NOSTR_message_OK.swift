import RAW

/// An acknowledgement sent by the server for the published event that the client sent.
public struct NOSTR_message_OK:Sendable, RAW_convertible {
	
	let type:NOSTR_message_type = NOSTR_message_type(RAW_native:0x105)
	
	public let eventID:NOSTR_id
	
	public let status:Bool
	
	public init(eventID:NOSTR_id, status:Bool) {
		self.eventID = eventID
		self.status = status
	}
	
	public init?(RAW_decode inputPtr:consuming UnsafeRawPointer, count: RAW.size_t) {
		guard count >= MemoryLayout<NOSTR_id>.size + MemoryLayout<Bytes1>.size + MemoryLayout<NOSTR_message_type>.size else { return nil }
		eventID = NOSTR_id(RAW_staticbuff_seeking: &inputPtr)
		status = Bytes1(RAW_staticbuff_seeking: &inputPtr).RAW_native() != 0
		let readType = NOSTR_message_type(RAW_staticbuff_seeking: &inputPtr)
		guard readType.RAW_native() == 0x105 else { return nil }
	}
	
	public func RAW_encode(count: inout RAW.size_t) {
		count += MemoryLayout<NOSTR_id>.size + MemoryLayout<Bytes1>.size + MemoryLayout<NOSTR_message_type>.size
	}
	
	public func RAW_encode(dest: UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
		var dest = eventID.RAW_encode(dest: dest)
		let statusBytes = Bytes1(RAW_native: status ? 1 : 0)
		dest = statusBytes.RAW_encode(dest: dest)
		return type.RAW_encode(dest: dest)
	}
}
