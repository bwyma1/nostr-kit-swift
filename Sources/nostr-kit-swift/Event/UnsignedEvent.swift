import RAW
import RAW_dh25519

@RAW_convertible_string_type<UTF8>(backing:RAW_byte.self)
public struct StringContent: NOSTR_event_content, Comparable, ExpressibleByStringLiteral { }

public struct NOSTR_tags: Sendable, Hashable {
	public var array: [any NOSTR_tag]
	
	public init(array: [any NOSTR_tag]) {
		self.array = array
	}

	public static func ==(lhs: NOSTR_tags, rhs: NOSTR_tags) -> Bool {
		guard lhs.array.count == rhs.array.count else { return false }
		for (a, b) in zip(lhs.array, rhs.array) {
			if a.hashValue != b.hashValue { return false } // or use `AnyHashable(a) == AnyHashable(b)`
		}
		return true
	}

	public func hash(into hasher: inout Hasher) {
		for item in array {
			hasher.combine(AnyHashable(item))
		}
	}
}

public struct UnsignedEvent<Content: NOSTR_event_content>:NOSTR_event_unsigned {
	
	public var id: NOSTR_id
	
	public var publicKey: PublicKey
	
	public var date: NOSTR_date
	
	public var tags: NOSTR_tags
	
	public var kind: NOSTR_kind
	
	public var content: Content
	
	public init(id: NOSTR_id, publicKey: PublicKey, date: NOSTR_date, tags: [any NOSTR_tag], kind: NOSTR_kind, content: Content) {
		self.id = id
		self.publicKey = publicKey
		self.date = date
		self.tags = NOSTR_tags(array: tags)
		self.kind = kind
		self.content = content
	}
	
	public init?(RAW_decode inputPtr:consuming UnsafeRawPointer, count: RAW.size_t) {
		guard MemoryLayout<NOSTR_id>.size + MemoryLayout<PublicKey>.size + MemoryLayout<NOSTR_date>.size + MemoryLayout<Bytes2>.size <= count else { return nil }
		var dataCount = count - (MemoryLayout<NOSTR_id>.size + MemoryLayout<PublicKey>.size + MemoryLayout<NOSTR_date>.size + MemoryLayout<Bytes2>.size)
		id = NOSTR_id(RAW_staticbuff_seeking: &inputPtr)
		publicKey = PublicKey(RAW_staticbuff_seeking: &inputPtr)
		date = NOSTR_date(RAW_staticbuff_seeking: &inputPtr)
		let tagCount = Bytes2(RAW_staticbuff_seeking: &inputPtr).RAW_native()
		var tagArray: [any NOSTR_tag] = []
		for _ in 0..<Int(tagCount) {
			guard dataCount >= MemoryLayout<Bytes4>.size else { return nil }
			let tagLength = Int(Bytes4(RAW_staticbuff_seeking: &inputPtr).RAW_native())
			dataCount -= MemoryLayout<Bytes4>.size
			guard let tag = EventTag(RAW_decode: inputPtr, count: tagLength) else { return nil }
			inputPtr = inputPtr.advanced(by: tagLength)
			dataCount -= tagLength
			tagArray.append(tag)
		}
		tags = NOSTR_tags(array: tagArray)
		guard dataCount >= MemoryLayout<NOSTR_kind>.size else { return nil }
		kind = NOSTR_kind(RAW_staticbuff_seeking: &inputPtr)
		dataCount -= MemoryLayout<NOSTR_kind>.size
		
		guard dataCount >= 0 else { return nil }
		guard let content = Content(RAW_decode: inputPtr, count: dataCount) else { return nil }
		self.content = content
	}
	
	public func RAW_encode(count: inout RAW.size_t) {
		for tag in tags.array {
			tag.RAW_encode(count: &count)
			count += MemoryLayout<Bytes4>.size
		}
		count += MemoryLayout<Bytes2>.size + MemoryLayout<NOSTR_id>.size + MemoryLayout<PublicKey>.size + MemoryLayout<NOSTR_date>.size + MemoryLayout<NOSTR_kind>.size
		content.RAW_encode(count: &count)
	}
	
	public func RAW_encode(dest: UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
		var dest = id.RAW_encode(dest: dest)
		dest = publicKey.RAW_encode(dest: dest)
		dest = date.RAW_encode(dest: dest)
		let tagCount = Bytes2(RAW_native: UInt16(tags.array.count))
		dest = tagCount.RAW_encode(dest: dest)
		for tag in tags.array {
			var tagLength = 0; tag.RAW_encode(count: &tagLength)
			let tagLengthBytes = Bytes4(RAW_native: UInt32(tagLength))
			dest = tagLengthBytes.RAW_encode(dest: dest)
			dest = tag.RAW_encode(dest: dest)
		}
		dest = kind.RAW_encode(dest: dest)
		dest = content.RAW_encode(dest: dest)
		return dest
	}
}


