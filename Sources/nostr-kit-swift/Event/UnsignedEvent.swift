import RAW
import RAW_dh25519

/// An event content type backed by a UTF-8 string.
@RAW_convertible_string_type<UTF8>(backing:RAW_byte.self)
public struct StringContent: NOSTR_event_content, Comparable, ExpressibleByStringLiteral { }

/// An ordered collection of tags attached to an event.
///
/// Tags are compared byte-level: two tags that encode to identical bytes are
/// considered equal regardless of their concrete Swift types.
public struct NOSTR_tags: Sendable, Hashable {
	/// The tags in the collection.
	public var array: [any NOSTR_tag]
	
	/// Creates a tag collection from an array of tags.
	public init(array: [any NOSTR_tag]) {
		self.array = array
	}

	public static func ==(lhs: NOSTR_tags, rhs: NOSTR_tags) -> Bool {
		guard lhs.array.count == rhs.array.count else { return false }
		for (a, b) in zip(lhs.array, rhs.array) {
			if !a.isEqual(to: b) { return false }
		}
		return true
	}

	public func hash(into hasher: inout Hasher) {
		for item in array {
			item.RAW_access_immutable { buffer in
				hasher.combine(bytes: UnsafeRawBufferPointer(buffer))
			}
		}
	}
}

/// A default unsigned event that follows the protocol.
public struct UnsignedEvent<Content: NOSTR_event_content>:NOSTR_event_unsigned {
	
	/// The event's unique identifier (SHA-256 of its serialized fields).
	///
	/// This is immutable once the event is created, so it can never diverge from
	/// the event's fields.
	public let id: NOSTR_id
	
	/// The public key of the event's author.
	public var publicKey: PublicKey
	
	/// The time at which the event was created.
	public var date: NOSTR_date
	
	/// The tags attached to the event.
	public var tags: NOSTR_tags
	
	/// The application to which the event belongs.
	public var application: NOSTR_application
	
	/// The kind of the event.
	public var kind: NOSTR_kind
	
	/// The event's content.
	public var content: Content
	
	/// Creates an unsigned event from its individual components.
	public init(id: NOSTR_id, publicKey: PublicKey, date: NOSTR_date, tags: [any NOSTR_tag], application: NOSTR_application, kind: NOSTR_kind, content: Content) {
		self.id = id
		self.publicKey = publicKey
		self.date = date
		self.tags = NOSTR_tags(array: tags)
		self.application = application
		self.kind = kind
		self.content = content
	}
	
	public init?(RAW_decode buffer: UnsafeRawBufferPointer) {
	guard let baseAddress = buffer.baseAddress else { return nil }
	var inputPtr = baseAddress
	let count = buffer.count
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
			guard dataCount >= tagLength else { return nil }
			guard let tag = EventTag(RAW_decode: UnsafeRawBufferPointer(start: inputPtr, count: tagLength)) else { return nil }
			inputPtr = inputPtr.advanced(by: tagLength)
			dataCount -= tagLength
			tagArray.append(tag)
		}
		tags = NOSTR_tags(array: tagArray)
		
		guard dataCount >= MemoryLayout<NOSTR_application>.size else { return nil }
		application = NOSTR_application(RAW_staticbuff_seeking: &inputPtr)
		dataCount -= MemoryLayout<NOSTR_application>.size
		
		guard dataCount >= MemoryLayout<NOSTR_kind>.size else { return nil }
		kind = NOSTR_kind(RAW_staticbuff_seeking: &inputPtr)
		dataCount -= MemoryLayout<NOSTR_kind>.size
		
		guard dataCount >= 0 else { return nil }
		guard let content = Content(RAW_decode: UnsafeRawBufferPointer(start: inputPtr, count: dataCount)) else { return nil }
		self.content = content
	}
	
	public func RAW_encode(count: inout Int) {
		for tag in tags.array {
			tag.RAW_encode(count: &count)
			count += MemoryLayout<Bytes4>.size
		}
		count += MemoryLayout<Bytes2>.size + MemoryLayout<NOSTR_id>.size + MemoryLayout<PublicKey>.size + MemoryLayout<NOSTR_date>.size + MemoryLayout<NOSTR_application>.size + MemoryLayout<NOSTR_kind>.size
		content.RAW_encode(count: &count)
	}
	
	public func RAW_encode(dest: UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
		var dest = id.RAW_encode(dest: dest)
		dest = publicKey.RAW_encode(dest: dest)
		dest = date.RAW_encode(dest: dest)
		precondition(tags.array.count <= Int(UInt16.max), "UnsignedEvent cannot encode \(tags.array.count) tags: the wire count field is 2 bytes (max \(Int(UInt16.max))).")
		let tagCount = Bytes2(RAW_native: UInt16(tags.array.count))
		dest = tagCount.RAW_encode(dest: dest)
		for tag in tags.array {
			var tagLength = 0; tag.RAW_encode(count: &tagLength)
			let tagLengthBytes = Bytes4(RAW_native: UInt32(tagLength))
			dest = tagLengthBytes.RAW_encode(dest: dest)
			dest = tag.RAW_encode(dest: dest)
		}
		dest = application.RAW_encode(dest: dest)
		dest = kind.RAW_encode(dest: dest)
		dest = content.RAW_encode(dest: dest)
		return dest
	}
	@discardableResult
	public func RAW_encode(_: UnsafeMutableRawPointer.Type, destination: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		return UnsafeMutableRawPointer(RAW_encode(dest: destination.assumingMemoryBound(to: UInt8.self)))
	}


}
