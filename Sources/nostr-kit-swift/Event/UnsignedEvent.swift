import RAW
import RAW_dh25519

@RAW_convertible_string_type<UTF8>(backing:RAW_byte.self)
public struct StringContent: NOSTR_event_content, Comparable, ExpressibleByStringLiteral { }

public struct UnsignedEvent<Content: NOSTR_event_content>:NOSTR_event_unsigned {
	
	public var id: NOSTR_id
	
	public var publicKey: PublicKey
	
	public var date: NOSTR_date
	
	public var tags: [any NOSTR_tag]
	
	public var kind: NOSTR_kind
	
	public var content: Content
	
	public init(id: NOSTR_id, publicKey: PublicKey, date: NOSTR_date, tags: [any NOSTR_tag], kind: NOSTR_kind, content: Content) {
		self.id = id
		self.publicKey = publicKey
		self.date = date
		self.tags = tags
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
		tags = []
		for _ in 0..<Int(tagCount) {
			guard dataCount >= MemoryLayout<Bytes4>.size else { return nil }
			let tagLength = Int(Bytes4(RAW_staticbuff_seeking: &inputPtr).RAW_native())
			dataCount -= MemoryLayout<Bytes4>.size
			guard let tag = EventTag(RAW_decode: inputPtr, count: tagLength) else { return nil }
			inputPtr = inputPtr.advanced(by: tagLength)
			dataCount -= tagLength
			tags.append(tag)
		}
		guard dataCount >= MemoryLayout<NOSTR_kind>.size else { return nil }
		kind = NOSTR_kind(RAW_staticbuff_seeking: &inputPtr)
		dataCount -= MemoryLayout<NOSTR_kind>.size
		
		guard dataCount >= 0 else { return nil }
		guard let content = Content(RAW_decode: inputPtr, count: dataCount) else { return nil }
		self.content = content
	}
	
	public func RAW_encode(count: inout RAW.size_t) {
		for tag in tags {
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
		let tagCount = Bytes2(RAW_native: UInt16(tags.count))
		dest = tagCount.RAW_encode(dest: dest)
		for tag in tags {
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


