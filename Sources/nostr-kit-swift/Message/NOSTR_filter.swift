import RAW
import RAW_dh25519

public struct Filter:Sendable, RAW_convertible {
	
	public var ids: [NOSTR_id]
	
	public var authors: [PublicKey]
	
	public var kinds: [NOSTR_kind]
	
	public var tags: [any NOSTR_tag]
	
	public var since: NOSTR_date?
	
	public var until: NOSTR_date?
	
	public init(ids: [NOSTR_id] = [], authors: [PublicKey] = [], kinds: [NOSTR_kind] = [], tags: [any NOSTR_tag] = [], since: NOSTR_date? = nil, until: NOSTR_date? = nil) {
		self.ids = ids
		self.authors = authors
		self.kinds = kinds
		self.tags = tags
		self.since = since
		self.until = until
	}
	
	public init?(RAW_decode inputPtr:consuming UnsafeRawPointer, count: RAW.size_t) {
		// ids
		guard count >= MemoryLayout<Bytes1>.size else { return nil }
		let idCount = Int(Bytes1(RAW_staticbuff_seeking: &inputPtr).RAW_native())
		guard count >= MemoryLayout<Bytes1>.size + MemoryLayout<NOSTR_id>.size * idCount else { return nil }
		ids = []
		for _ in 0..<idCount{
			let id = NOSTR_id(RAW_staticbuff_seeking: &inputPtr)
			ids.append(id)
		}
		var dataCount = count - MemoryLayout<Bytes1>.size - MemoryLayout<NOSTR_id>.size * idCount
		
		// authors
		guard dataCount >= MemoryLayout<Bytes1>.size else { return nil }
		let authorCount = Int(Bytes1(RAW_staticbuff_seeking: &inputPtr).RAW_native())
		guard dataCount >= MemoryLayout<Bytes1>.size + MemoryLayout<PublicKey>.size * authorCount else { return nil }
		authors = []
		for _ in 0..<authorCount{
			let author = PublicKey(RAW_staticbuff_seeking: &inputPtr)
			authors.append(author)
		}
		dataCount = count - MemoryLayout<Bytes1>.size - MemoryLayout<PublicKey>.size * authorCount
		
		// kinds
		guard dataCount >= MemoryLayout<Bytes1>.size else { return nil }
		let kindCount = Int(Bytes1(RAW_staticbuff_seeking: &inputPtr).RAW_native())
		guard dataCount >= MemoryLayout<Bytes1>.size + MemoryLayout<NOSTR_kind>.size * kindCount else { return nil }
		kinds = []
		for _ in 0..<kindCount{
			let kind = NOSTR_kind(RAW_staticbuff_seeking: &inputPtr)
			kinds.append(kind)
		}
		dataCount = count - MemoryLayout<Bytes1>.size - MemoryLayout<NOSTR_kind>.size * kindCount
		
		// tags
		let tagCount = Bytes1(RAW_staticbuff_seeking: &inputPtr).RAW_native()
		tags = []
		for _ in 0..<Int(tagCount) {
			guard dataCount >= MemoryLayout<Bytes4>.size else { return nil }
			let tagLength = Int(Bytes4(RAW_staticbuff_seeking: &inputPtr).RAW_native())
			guard let tag = EventTag(RAW_decode: inputPtr, count: tagLength) else { return nil }
			inputPtr = inputPtr.advanced(by: tagLength)
			dataCount -= tagLength
			tags.append(tag)
		}
		
		// since / until
		guard dataCount >= MemoryLayout<Bytes1>.size else { return nil }
		let sinceExists = Int(Bytes1(RAW_staticbuff_seeking: &inputPtr).RAW_native())
		dataCount -= MemoryLayout<Bytes1>.size
		if sinceExists == 1 {
			guard dataCount >= MemoryLayout<NOSTR_date>.size else { return nil }
			since = NOSTR_date(RAW_staticbuff_seeking: &inputPtr)
			dataCount -= MemoryLayout<NOSTR_date>.size
		}
		guard dataCount >= MemoryLayout<Bytes1>.size else { return nil }
		let untilExists = Int(Bytes1(RAW_staticbuff_seeking: &inputPtr).RAW_native())
		dataCount -= MemoryLayout<Bytes1>.size
		if untilExists == 1 {
			guard dataCount >= MemoryLayout<NOSTR_date>.size else { return nil }
			until = NOSTR_date(RAW_staticbuff_seeking: &inputPtr)
		}
	}
	
	public func RAW_encode(count: inout RAW.size_t) {
		// ids | author | kind | tag | since | until
		count += MemoryLayout<Bytes1>.size * 6
		for id in ids {
			id.RAW_encode(count: &count)
		}
		for author in authors {
			author.RAW_encode(count: &count)
		}
		for kind in kinds {
			kind.self.RAW_encode(count: &count)
		}
		for tag in tags {
			tag.RAW_encode(count: &count)
			count += MemoryLayout<Bytes4>.size
		}
		if since != nil {
			count += MemoryLayout<NOSTR_date>.size
		}
		if until != nil {
			count += MemoryLayout<NOSTR_date>.size
		}
	}
	
	public func RAW_encode(dest: UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
		// ids
		let idCount = Bytes1(RAW_native: UInt8(ids.count))
		var dest = idCount.RAW_encode(dest: dest)
		for id in ids {
			dest = id.RAW_encode(dest: dest)
		}
		
		// authors
		let authorCount = Bytes1(RAW_native: UInt8(authors.count))
		dest = authorCount.RAW_encode(dest: dest)
		for author in authors {
			dest = author.RAW_encode(dest: dest)
		}
		
		// kinds
		let kindCount = Bytes1(RAW_native: UInt8(kinds.count))
		dest = kindCount.RAW_encode(dest: dest)
		for kind in kinds {
			dest = kind.RAW_encode(dest: dest)
		}
		
		// tags
		let tagCount = Bytes1(RAW_native: UInt8(tags.count))
		dest = tagCount.RAW_encode(dest: dest)
		for tag in tags {
			var tagLength = 0; tag.RAW_encode(count: &tagLength)
			let tagLengthBytes = Bytes4(RAW_native: UInt32(tagLength))
			dest = tagLengthBytes.RAW_encode(dest: dest)
			dest = tag.RAW_encode(dest: dest)
		}
		
		// since / until
		var exists = Bytes1(RAW_native: UInt8(since == nil ? 0 : 1))
		dest = exists.RAW_encode(dest: dest)
		if let since = since {
			dest = since.RAW_encode(dest: dest)
		}
		exists = Bytes1(RAW_native: UInt8(until == nil ? 0 : 1))
		dest = exists.RAW_encode(dest: dest)
		if let until = until {
			dest = until.RAW_encode(dest: dest)
		}
		
		return dest
	}
}
