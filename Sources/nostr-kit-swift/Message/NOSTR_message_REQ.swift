import RAW
import RAW_dh25519

/// Sent by the client to the server with an array of filters.
///
/// The server stores the REQ for the subscription and sends over the filtered data.
/// The server continues to send filtered data until the REQ is replaced with a new
/// REQ filter or the server receives a CLOSE message.
public struct NOSTR_message_REQ:Sendable, RAW_convertible {
	
	let type:NOSTR_message_type = NOSTR_message_type(RAW_native:0x100)
	
	/// The subscription identifier for this request.
	public let subscriptionID:NOSTR_subscription_ID
	
	/// The filters describing which events the client wants.
	public var filters:[Filter]
	
	/// The requesting user's public key.
	public var user:PublicKey
	
	/// Whether to fetch historical events for the subscription.
	public var fetchHistory:Encoded.Bool
	
	/// Creates a REQ message from a subscription identifier, filters, user, and history flag.
	public init(subscriptionID:String, filters:[Filter], from user:PublicKey, fetchHistory:Bool) {
		self.subscriptionID = NOSTR_subscription_ID(stringLiteral: subscriptionID)
		self.filters = filters
		self.user = user
		self.fetchHistory = Encoded.Bool(fetchHistory)
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
		guard readType.RAW_native() == 0x100 else { return nil }
		dataCount -= MemoryLayout<NOSTR_message_type>.size
		
		guard dataCount >= MemoryLayout<Bytes1>.size else { return nil }
		let filterCount = Int(Bytes1(RAW_staticbuff_seeking: &inputPtr).RAW_native())
		dataCount -= MemoryLayout<Bytes1>.size
		
		var filters:[Filter] = []
		for _ in 0..<filterCount {
			guard dataCount >= MemoryLayout<Bytes4>.size else { return nil }
			let filterLength = Int(Bytes4(RAW_staticbuff_seeking: &inputPtr).RAW_native())
			dataCount -= MemoryLayout<Bytes4>.size
			guard dataCount >= filterLength else { return nil }
			guard let filter = Filter(RAW_decode: inputPtr, count: filterLength) else { return nil }
			inputPtr = inputPtr.advanced(by: filterLength)
			dataCount -= filterLength
			filters.append(filter)
		}
		self.filters = filters
		
		guard dataCount >= MemoryLayout<PublicKey>.size else { return nil }
		self.user = PublicKey(RAW_staticbuff_seeking: &inputPtr)
		dataCount -= MemoryLayout<PublicKey>.size
		
		guard dataCount >= MemoryLayout<Encoded.Bool>.size else { return nil }
		self.fetchHistory = Encoded.Bool(RAW_staticbuff_seeking: &inputPtr)
		dataCount -= MemoryLayout<Encoded.Bool>.size
		
		guard dataCount == 0 else { return nil }
	}
	
	public func RAW_encode(count: inout RAW.size_t) {
		count += MemoryLayout<NOSTR_message_type>.size + MemoryLayout<PublicKey>.size + MemoryLayout<Bytes1>.size + MemoryLayout<Bytes4>.size * (filters.count + 1) + MemoryLayout<Encoded.Bool>.size
		subscriptionID.RAW_encode(count: &count)
		for filter in filters {
			filter.RAW_encode(count: &count)
		}
	}
	
	public func RAW_encode(dest: UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
		var subscriptionIDLength = 0; subscriptionID.RAW_encode(count: &subscriptionIDLength)
		let subscriptionIDLengthBytes = Bytes4(RAW_native: UInt32(subscriptionIDLength))
		var dest = subscriptionIDLengthBytes.RAW_encode(dest: dest)
		dest = subscriptionID.RAW_encode(dest: dest)
		
		dest = type.RAW_encode(dest: dest)
		let filterCount = Bytes1(RAW_native: UInt8(filters.count))
		dest = filterCount.RAW_encode(dest: dest)
		for filter in filters {
			var filterLength = 0; filter.RAW_encode(count: &filterLength)
			let filterLengthBytes = Bytes4(RAW_native: UInt32(filterLength))
			dest = filterLengthBytes.RAW_encode(dest: dest)
			dest = filter.RAW_encode(dest: dest)
		}
		
		dest = user.RAW_encode(dest: dest)
		dest = fetchHistory.RAW_encode(dest: dest)
		return dest
	}
}
