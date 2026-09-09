import RAW

/// A message sent by the client to a server signaling the closure of a REQ for the subscription.
///
/// The server stops sending events for the given subscription when it receives this
/// message.
public struct NOSTR_message_CLOSE:Sendable, RAW_decodable, RAW_encodable {
	
	let type:NOSTR_message_type = NOSTR_message_type(RAW_native:0x103)
	
	/// The subscription identifier being closed.
	public let subscriptionID:NOSTR_subscription_ID
		
	/// Creates a CLOSE message for the given subscription identifier string.
	public init(subscriptionID:String) {
		self.subscriptionID = NOSTR_subscription_ID(stringLiteral: subscriptionID)
	}
	
	public init?(RAW_decode buffer: UnsafeRawBufferPointer) {
	guard let baseAddress = buffer.baseAddress else { return nil }
	var inputPtr = baseAddress
	let count = buffer.count
		guard count >= MemoryLayout<Bytes4>.size else { return nil }
		let subscriptionIDLength = Int(Bytes4(RAW_staticbuff_seeking: &inputPtr).RAW_native())
		var dataCount = count - MemoryLayout<Bytes4>.size
		guard dataCount >= subscriptionIDLength else { return nil }
		guard let subscriptionID = NOSTR_subscription_ID(RAW_decode: UnsafeRawBufferPointer(start: inputPtr, count: subscriptionIDLength)) else { return nil }
		self.subscriptionID = subscriptionID
		inputPtr = inputPtr.advanced(by: subscriptionIDLength)
		dataCount -= subscriptionIDLength
		
		guard dataCount >= MemoryLayout<NOSTR_message_type>.size else { return nil }
		let readType = NOSTR_message_type(RAW_staticbuff_seeking: &inputPtr)
		guard readType.RAW_native() == 0x103 else { return nil }
	}
	
	public func RAW_encode(count: inout Int) {
		subscriptionID.RAW_encode(count: &count)
		count += MemoryLayout<NOSTR_message_type>.size + MemoryLayout<Bytes4>.size
	}
	
	public func RAW_encode(dest: UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
		var subscriptionIDLength = 0; subscriptionID.RAW_encode(count: &subscriptionIDLength)
		let subscriptionIDLengthBytes = Bytes4(RAW_native: UInt32(subscriptionIDLength))
		var dest = subscriptionIDLengthBytes.RAW_encode(dest: dest)
		dest = subscriptionID.RAW_encode(dest: dest)
		
		return type.RAW_encode(dest: dest)
	}
	@discardableResult
	public func RAW_encode(_: UnsafeMutableRawPointer.Type, destination: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		return UnsafeMutableRawPointer(RAW_encode(dest: destination.assumingMemoryBound(to: UInt8.self)))
	}


}
