import RAW

public enum NOSTR_message_error: Error {
	case badDecode
}

public enum NOSTR_message<UnsignedEvent: NOSTR_event_unsigned> {
	case REQ(NOSTR_message_REQ)
	case EVENT(NOSTR_message_EVENT<UnsignedEvent>)
	case CLOSE(NOSTR_message_CLOSE)
}

@RAW_staticbuff(bytes:4)
@RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian: true)
internal struct NOSTR_message_type:Sendable, Comparable, RAW_convertible { }

public struct NOSTR_message_REQ:Sendable, RAW_convertible {
	
	let type:NOSTR_message_type = NOSTR_message_type(RAW_native:0x99)
	
	public var filters:[Filter]
	
	public init(filters:[Filter]) {
		self.filters = filters
	}
	
	public init?(RAW_decode inputPtr:consuming UnsafeRawPointer, count: RAW.size_t) {
		guard count >= MemoryLayout<NOSTR_message_type>.size else { return nil }
		let readType = NOSTR_message_type(RAW_staticbuff_seeking: &inputPtr)
		guard readType.RAW_native() == 0x99 else { return nil }
		var dataCount = count - MemoryLayout<NOSTR_message_type>.size
		
		guard dataCount >= MemoryLayout<Bytes1>.size else { return nil }
		let filterCount = Int(Bytes1(RAW_staticbuff_seeking: &inputPtr).RAW_native())
		dataCount -= MemoryLayout<Bytes1>.size
		
		var filters:[Filter] = []
		for _ in 0..<filterCount {
			guard dataCount >= MemoryLayout<Bytes4>.size else { return nil }
			let filterLength = Int(Bytes4(RAW_staticbuff_seeking: &inputPtr).RAW_native())
			dataCount -= MemoryLayout<Bytes4>.size
			guard dataCount >= 0 else { return nil }
			guard let filter = Filter(RAW_decode: inputPtr, count: filterLength) else { return nil }
			inputPtr = inputPtr.advanced(by: filterLength)
			dataCount -= filterLength
			filters.append(filter)
		}
		self.filters = filters
	}
	
	public func RAW_encode(count: inout RAW.size_t) {
		count += MemoryLayout<NOSTR_message_type>.size + MemoryLayout<Bytes1>.size + MemoryLayout<Bytes4>.size * filters.count
		for filter in filters {
			filter.RAW_encode(count: &count)
		}
	}
	
	public func RAW_encode(dest: UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
		var dest = type.RAW_encode(dest: dest)
		let filterCount = Bytes1(RAW_native: UInt8(filters.count))
		dest = filterCount.RAW_encode(dest: dest)
		for filter in filters {
			var filterLength = 0; filter.RAW_encode(count: &filterLength)
			let filterLengthBytes = Bytes4(RAW_native: UInt32(filterLength))
			dest = filterLengthBytes.RAW_encode(dest: dest)
			dest = filter.RAW_encode(dest: dest)
		}
		return dest
	}
}

public struct NOSTR_message_EVENT<UnsignedEvent:NOSTR_event_unsigned>:Sendable, RAW_convertible {
	
	let type:NOSTR_message_type = NOSTR_message_type(RAW_native:0x100)
	
	public let event:NOSTR_event_signed<UnsignedEvent>
	
	public init(event:NOSTR_event_signed<UnsignedEvent>) {
		self.event = event
	}
	
	public init?(RAW_decode inputPtr:consuming UnsafeRawPointer, count: RAW.size_t) {
		guard count >= MemoryLayout<NOSTR_message_type>.size else { return nil }
		let readType = NOSTR_message_type(RAW_staticbuff_seeking: &inputPtr)
		guard readType.RAW_native() == 0x100 else { return nil }
		let dataCount = count - MemoryLayout<NOSTR_message_type>.size
		guard dataCount >= 0 else { return nil }
		guard let event = NOSTR_event_signed<UnsignedEvent>(RAW_decode: inputPtr, count: dataCount) else { return nil }
		self.event = event
	}
	
	public func RAW_encode(count: inout RAW.size_t) {
		count += MemoryLayout<NOSTR_message_type>.size
		event.RAW_encode(count: &count)
	}
	
	public func RAW_encode(dest: UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
		let dest = type.RAW_encode(dest: dest)
		return event.RAW_encode(dest: dest)
	}
	
}

public struct NOSTR_message_CLOSE:Sendable, RAW_convertible {
	
	let type:NOSTR_message_type = NOSTR_message_type(RAW_native:0x101)
	
	public init() {}
	
	public init?(RAW_decode inputPtr:consuming UnsafeRawPointer, count: RAW.size_t) {
		guard count >= MemoryLayout<NOSTR_message_type>.size else { return nil }
		let readType = NOSTR_message_type(RAW_staticbuff_seeking: &inputPtr)
		guard readType.RAW_native() == 0x101 else { return nil }
	}
	
	public func RAW_encode(count: inout RAW.size_t) {
		count = MemoryLayout<NOSTR_message_type>.size
	}
	
	public func RAW_encode(dest: UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
		return type.RAW_encode(dest: dest)
	}
}
