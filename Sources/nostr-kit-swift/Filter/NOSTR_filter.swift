import RAW
import RAW_dh25519

/// A limit value for a filter query.
@RAW_staticbuff(bytes: 8)
@RAW_staticbuff_fixedwidthinteger_type<UInt64>(bigEndian:true)
public struct NOSTR_filter_limit:Sendable { }

/// A filter that matches events against a set of conditions.
///
/// List attributes (ids, authors, kinds, and tag filters like `#e`) match when the
/// event's value is contained in the list. For tags, the event must have at least
/// one tag value matching one value in the filter list.
///
/// Time range (since and until): events match when `since <= created_at <= until`.
///
/// Multiple conditions within a single filter must all be satisfied (logical AND).
/// If multiple filters are provided, an event matches when it satisfies any filter
/// (logical OR).
///
/// Limits only apply to the initial query and are ignored for ongoing subscriptions.
public struct Filter:Sendable, RAW_convertible {
	
	/// The event ids to match.
	public var ids: [NOSTR_id]
	
	/// The author public keys to match.
	public var authors: [PublicKey]
	
	/// The applications to match.
	public var applications: [NOSTR_application]
	
	/// The kinds to match.
	public var kinds: [NOSTR_kind]
	
	/// The tag filters to match.
	public var tags: [any NOSTR_tag]
	
	/// Only match events created at or after this time.
	public var since: NOSTR_date?
	
	/// Only match events created at or before this time.
	public var until: NOSTR_date?
	
	/// The maximum number of events to return for the initial query.
	public var limit: NOSTR_filter_limit?
	
	/// Creates a filter from typed values.
	public init(ids: [NOSTR_id] = [], authors: [PublicKey] = [], applications: [NOSTR_application] = [], kinds: [NOSTR_kind] = [], tags: [any NOSTR_tag] = [], since: NOSTR_date? = nil, until: NOSTR_date? = nil, limit: NOSTR_filter_limit? = nil) {
		self.ids = ids
		self.authors = authors
		self.applications = applications
		self.kinds = kinds
		self.tags = tags
		self.since = since
		self.until = until
		self.limit = limit
	}
	
	/// Creates a filter from native `UInt16`/`UInt32` values for applications and kinds.
	public init(ids: [NOSTR_id] = [], authors: [PublicKey] = [], applications: [UInt16], kinds: [UInt32], tags: [any NOSTR_tag] = [], since: NOSTR_date? = nil, until: NOSTR_date? = nil, limit: NOSTR_filter_limit? = nil) {
		self.ids = ids
		self.authors = authors
		self.applications = applications.map { NOSTR_application(RAW_native: $0) }
		self.kinds = kinds.map { NOSTR_kind(RAW_native: $0) }
		self.tags = tags
		self.since = since
		self.until = until
		self.limit = limit
	}
	
	public init?(RAW_decode inputPtr:consuming UnsafeRawPointer, count: RAW.size_t) {
		var dataCount = count

		// ids
		guard dataCount >= MemoryLayout<Bytes1>.size else { return nil }
		let idCount = Int(Bytes1(RAW_staticbuff_seeking: &inputPtr).RAW_native())
		dataCount -= MemoryLayout<Bytes1>.size
		guard dataCount >= MemoryLayout<NOSTR_id>.size * idCount else { return nil }
		ids = []
		for _ in 0..<idCount{
			let id = NOSTR_id(RAW_staticbuff_seeking: &inputPtr)
			ids.append(id)
		}
		dataCount -= MemoryLayout<NOSTR_id>.size * idCount

		// authors
		guard dataCount >= MemoryLayout<Bytes1>.size else { return nil }
		let authorCount = Int(Bytes1(RAW_staticbuff_seeking: &inputPtr).RAW_native())
		dataCount -= MemoryLayout<Bytes1>.size
		guard dataCount >= MemoryLayout<PublicKey>.size * authorCount else { return nil }
		authors = []
		for _ in 0..<authorCount{
			let author = PublicKey(RAW_staticbuff_seeking: &inputPtr)
			authors.append(author)
		}
		dataCount -= MemoryLayout<PublicKey>.size * authorCount

		// applications
		guard dataCount >= MemoryLayout<Bytes1>.size else { return nil }
		let applicationCount = Int(Bytes1(RAW_staticbuff_seeking: &inputPtr).RAW_native())
		dataCount -= MemoryLayout<Bytes1>.size
		guard dataCount >= MemoryLayout<NOSTR_application>.size * applicationCount else { return nil }
		applications = []
		for _ in 0..<applicationCount{
			let application = NOSTR_application(RAW_staticbuff_seeking: &inputPtr)
			applications.append(application)
		}
		dataCount -= MemoryLayout<NOSTR_application>.size * applicationCount

		// kinds
		guard dataCount >= MemoryLayout<Bytes1>.size else { return nil }
		let kindCount = Int(Bytes1(RAW_staticbuff_seeking: &inputPtr).RAW_native())
		dataCount -= MemoryLayout<Bytes1>.size
		guard dataCount >= MemoryLayout<NOSTR_kind>.size * kindCount else { return nil }
		kinds = []
		for _ in 0..<kindCount{
			let kind = NOSTR_kind(RAW_staticbuff_seeking: &inputPtr)
			kinds.append(kind)
		}
		dataCount -= MemoryLayout<NOSTR_kind>.size * kindCount

		// tags
		guard dataCount >= MemoryLayout<Bytes1>.size else { return nil }
		let tagCount = Int(Bytes1(RAW_staticbuff_seeking: &inputPtr).RAW_native())
		dataCount -= MemoryLayout<Bytes1>.size
		tags = []
		for _ in 0..<tagCount {
			guard dataCount >= MemoryLayout<Bytes4>.size else { return nil }
			let tagLength = Int(Bytes4(RAW_staticbuff_seeking: &inputPtr).RAW_native())
			dataCount -= MemoryLayout<Bytes4>.size
			guard dataCount >= tagLength else { return nil }
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
			dataCount -= MemoryLayout<NOSTR_date>.size
		}

		// limit
		guard dataCount >= MemoryLayout<Bytes1>.size else { return nil }
		let limitExists = Int(Bytes1(RAW_staticbuff_seeking: &inputPtr).RAW_native())
		dataCount -= MemoryLayout<Bytes1>.size
		if limitExists == 1 {
			guard dataCount >= MemoryLayout<NOSTR_filter_limit>.size else { return nil }
			limit = NOSTR_filter_limit(RAW_staticbuff_seeking: &inputPtr)
			dataCount -= MemoryLayout<NOSTR_filter_limit>.size
		}

		guard dataCount == 0 else { return nil }
	}
	
	public func RAW_encode(count: inout RAW.size_t) {
		// ids | author | application | kind | tag | since | until | limit
		count += MemoryLayout<Bytes1>.size * 8
		for id in ids {
			id.RAW_encode(count: &count)
		}
		for author in authors {
			author.RAW_encode(count: &count)
		}
		for application in applications {
			application.self.RAW_encode(count: &count)
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
		if limit != nil {
			count += MemoryLayout<NOSTR_filter_limit>.size
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
		
		// applications
		let applicationCount = Bytes1(RAW_native: UInt8(applications.count))
		dest = applicationCount.RAW_encode(dest: dest)
		for application in applications {
			dest = application.RAW_encode(dest: dest)
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
		
		// limit
		exists = Bytes1(RAW_native: UInt8(limit == nil ? 0 : 1))
		dest = exists.RAW_encode(dest: dest)
		if let limit = limit {
			dest = limit.RAW_encode(dest: dest)
		}
		
		return dest
	}
}


extension Filter {
	/// Applies this filter to a signed event.
	/// Returns `true` if the signed event matches the filter, otherwise `false`.
	public func apply<UnsignedEvent:NOSTR_event_unsigned>(to event: NOSTR_event_signed<UnsignedEvent>) -> Bool {
		// make sure each filter tag is in the event tags
		var hasTags: Bool = true
		tagLoop: for tag in self.tags {
			for eventTag in event.unsignedEvent.tags.array {
				guard tag.indexField == eventTag.indexField else {
					continue
				}
				// At least one value from the event must appear in the filter values
				if eventTag.value.isEqual(to: tag.value) {
					continue tagLoop
				}
			}
			hasTags = false
		}
		if((self.ids == [] || self.ids.contains(event.unsignedEvent.id)) &&
		   (self.authors == [] || self.authors.contains(event.unsignedEvent.publicKey)) &&
		   (self.applications == [] || self.applications.contains(event.unsignedEvent.application)) &&
		   (self.kinds == [] || self.kinds.contains(event.unsignedEvent.kind)) &&
		   (self.since == nil || self.since! <= event.unsignedEvent.date) &&
		   (self.until == nil || self.until! >= event.unsignedEvent.date) &&
		   hasTags) {
			return true
		}
		return false
	}
}
