import RAW

/// An acknowledgement sent by the server for the published event that the client sent.
public struct NOSTR_message_OK:Sendable, RAW_decodable, RAW_encodable {
	
	let type:NOSTR_message_type = NOSTR_message_type(RAW_native:0x105)
	
	/// The identifier of the event being acknowledged.
	public let eventID:NOSTR_id
	
	/// Whether the server accepted the event.
	public let status:Bool
	
	/// Creates an OK message for the given event identifier and acceptance status.
	public init(eventID:NOSTR_id, status:Bool) {
		self.eventID = eventID
		self.status = status
	}
	
	public init?(RAW_decode buffer: UnsafeRawBufferPointer) {
		guard let baseAddress = buffer.baseAddress else { return nil }
		var inputPtr = baseAddress
		let count = buffer.count
		guard count >= MemoryLayout<NOSTR_id>.size + MemoryLayout<Bytes1>.size + MemoryLayout<NOSTR_message_type>.size else { return nil }
		eventID = NOSTR_id(RAW_staticbuff_seeking: &inputPtr)
		status = Bytes1(RAW_staticbuff_seeking: &inputPtr).RAW_native() != 0
		let readType = NOSTR_message_type(RAW_staticbuff_seeking: &inputPtr)
		guard readType.RAW_native() == 0x105 else { return nil }
	}
	
	public func RAW_encode(count: inout Int) {
		count += MemoryLayout<NOSTR_id>.size + MemoryLayout<Bytes1>.size + MemoryLayout<NOSTR_message_type>.size
	}
	
	public func RAW_encode(dest: UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
		var dest = eventID.RAW_encode(dest: dest)
		let statusBytes = Bytes1(RAW_native: status ? 1 : 0)
		dest = statusBytes.RAW_encode(dest: dest)
		return type.RAW_encode(dest: dest)
	}
	@discardableResult
	public func RAW_encode(_: UnsafeMutableRawPointer.Type, destination: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		return UnsafeMutableRawPointer(RAW_encode(dest: destination.assumingMemoryBound(to: UInt8.self)))
	}
}
