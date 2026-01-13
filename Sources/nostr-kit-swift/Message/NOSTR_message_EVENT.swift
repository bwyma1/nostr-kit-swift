import RAW

/// Client --> Server
/// - A message sent by the client to a server containing a `NOSTR_signed_event` to be saved to the database.
/// - Subscription ID does not affect the message.
/// Server --> Client
/// - A message sent by the server to the client for requested events.
/// - Subscription ID represents what subscription the event belongs to.
public struct NOSTR_message_EVENT<UnsignedEvent:NOSTR_event_unsigned>:Sendable, RAW_convertible {
	
	let type:NOSTR_message_type = NOSTR_message_type(RAW_native:0x101)
	
	public let subscriptionID:NOSTR_subscription_ID
	
	public let event:NOSTR_event_signed<UnsignedEvent>
	
	public init(subscriptionID:String, event:NOSTR_event_signed<UnsignedEvent>) {
		self.subscriptionID = NOSTR_subscription_ID(stringLiteral: subscriptionID)
		self.event = event
	}
	
	public init?(RAW_decode inputPtr:consuming UnsafeRawPointer, count: RAW.size_t) {
		guard count >= MemoryLayout<Bytes4>.size else { return nil }
		let subscriptionIDLength = Int(Bytes4(RAW_staticbuff_seeking: &inputPtr).RAW_native())
		var dataCount = count - MemoryLayout<Bytes4>.size
		guard dataCount >= subscriptionIDLength else { return nil }
		self.subscriptionID = NOSTR_subscription_ID(RAW_decode: inputPtr, count: subscriptionIDLength)
		inputPtr = inputPtr.advanced(by: subscriptionIDLength)
		dataCount -= subscriptionIDLength
		
		guard dataCount >= MemoryLayout<NOSTR_message_type>.size else { return nil }
		let readType = NOSTR_message_type(RAW_staticbuff_seeking: &inputPtr)
		guard readType.RAW_native() == 0x101 else { return nil }
		dataCount -= MemoryLayout<NOSTR_message_type>.size
		guard dataCount >= 0 else { return nil }
		guard let event = NOSTR_event_signed<UnsignedEvent>(RAW_decode: inputPtr, count: dataCount) else { return nil }
		self.event = event
	}
	
	public func RAW_encode(count: inout RAW.size_t) {
		count += MemoryLayout<NOSTR_message_type>.size
		subscriptionID.RAW_encode(count: &count)
		event.RAW_encode(count: &count)
	}
	
	public func RAW_encode(dest: UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
		var subscriptionIDLength = 0; subscriptionID.RAW_encode(count: &subscriptionIDLength)
		let subscriptionIDLengthBytes = Bytes4(RAW_native: UInt32(subscriptionIDLength))
		var dest = subscriptionIDLengthBytes.RAW_encode(dest: dest)
		dest = subscriptionID.RAW_encode(dest: dest)
		
		dest = type.RAW_encode(dest: dest)
		return event.RAW_encode(dest: dest)
	}
	
}
