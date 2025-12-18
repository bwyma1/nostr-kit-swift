import RAW
import RAW_dh25519
import RAW_sha256
import RAW_ed25519

public typealias PublicKey = RAW_dh25519.PublicKey

public protocol NOSTR_event_content: Sendable, RAW_convertible { }

public protocol NOSTR_event_unsigned: Sendable, Identifiable, RAW_convertible {
	
	var id:NOSTR_id { get }
	
	var publicKey:PublicKey { get set }
	
	var date:NOSTR_date { get set }
	
	var tags:[any NOSTR_tag] { get set }
	
	var kind:NOSTR_kind { get set }
	
	var content:NOSTR_event_content { get set }
	
	init(id:NOSTR_id, publicKey:PublicKey, date:NOSTR_date, tags:[any NOSTR_tag], kind:NOSTR_kind, content:NOSTR_event_content)
}

extension NOSTR_event_unsigned {
	public init(publicKey:PublicKey, date:NOSTR_date, tags:[any NOSTR_tag], kind:NOSTR_kind, content:NOSTR_event_content) throws {
		var hasher = RAW_sha256.Hasher<NOSTR_id>()
		
		try hasher.update(publicKey)
		try hasher.update(date)
		for tag in tags {
			var tagLength = 0; tag.RAW_encode(count: &tagLength)
			let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: tagLength)
			defer { buffer.deallocate() }
			tag.RAW_encode(dest: buffer.baseAddress!)
			try hasher.update(buffer)
		}
		try hasher.update(kind)
		
		var contentLength = 0; content.RAW_encode(count: &contentLength)
		let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: contentLength)
		defer { buffer.deallocate() }
		content.RAW_encode(dest: buffer.baseAddress!)
		try hasher.update(buffer)
		
		var id = NOSTR_id(RAW_staticbuff: NOSTR_id.RAW_staticbuff_zeroed())
		try id.RAW_access_staticbuff_mutating({ ptr in
			try hasher.finish(into: ptr)
		})
		
		self = Self(id: id, publicKey: publicKey, date: date, tags: tags, kind: kind, content: content)
	}
}

extension NOSTR_event_unsigned {
	/// Sign the `NOSTR_event_unsigned` using the authors `PrivateKey`.
	/// The event should only ever be signed once.
	/// The event should be signed once it has been confirmed to be finalized.
	public func sign(as author:MemoryGuarded<Ed25519.PrivateKey>) throws -> NOSTR_event_signed {
		var sig = NOSTR_sig(RAW_staticbuff: NOSTR_sig.RAW_staticbuff_zeroed())
		sig.RAW_access_mutating { sigPtr in
			id.RAW_access { msgPtr in
				Ed25519.sign(signature: sigPtr.baseAddress!, privateKey: author, message: msgPtr)
			}
		}
		return NOSTR_event_signed(unsignedEvent: self, sig: sig)
	}
}

public struct NOSTR_event_signed: Sendable, Identifiable, RAW_convertible, RAW_accessible {
	public func RAW_access<R, E>(_ body: (UnsafeBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E : Error {
		var count: RAW.size_t = 0
		self.RAW_encode(count: &count)
		
		return try! withUnsafeTemporaryAllocation(
			byteCount: count,
			alignment: MemoryLayout<UInt8>.alignment
		) { rawBuffer in
			let base = rawBuffer.baseAddress!.assumingMemoryBound(to: UInt8.self)
			_ = self.RAW_encode(dest: base)

			let buffer = UnsafeBufferPointer(start: base, count: count)
			return try body(buffer)
		}
	}
	
	public mutating func RAW_access_mutating<R, E>(_ body: (UnsafeMutableBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E : Error {
		var count: RAW.size_t = 0
		self.RAW_encode(count: &count)

		return try! withUnsafeTemporaryAllocation(
			byteCount: count,
			alignment: MemoryLayout<UInt8>.alignment
		) { rawBuffer in
			let base = rawBuffer.baseAddress!.assumingMemoryBound(to: UInt8.self)
			_ = self.RAW_encode(dest: base)

			let buffer = UnsafeMutableBufferPointer(start: base, count: count)
			let result = try body(buffer)

			// Re-decode into self
			let readPtr = UnsafeRawPointer(base)
			guard let decoded = NOSTR_event_signed(
				RAW_decode: readPtr,
				count: count
			) else {
				fatalError("RAW_access_mutating produced invalid state")
			}

			self = decoded
			return result
		}
	}
	
	
	public let sig:NOSTR_sig
	public var id: NOSTR_sig {
		sig
	}
	
	public let unsignedEvent:any NOSTR_event_unsigned
	
	public init(unsignedEvent:any NOSTR_event_unsigned, sig:NOSTR_sig) {
		self.unsignedEvent = unsignedEvent
		self.sig = sig
	}
	
	public init?(RAW_decode inputPtr:consuming UnsafeRawPointer, count: RAW.size_t) {
		guard count >= MemoryLayout<NOSTR_sig>.size else { return nil }
		sig = NOSTR_sig(RAW_staticbuff_seeking: &inputPtr)
		let unsignedEventCount = count - MemoryLayout<NOSTR_sig>.size
		guard let unsignedEvent = UnsignedEvent(RAW_decode: inputPtr, count: unsignedEventCount) else { return nil }
		self.unsignedEvent = unsignedEvent
	}
	
	public func RAW_encode(count: inout RAW.size_t) {
		sig.RAW_encode(count: &count)
		unsignedEvent.RAW_encode(count: &count)
	}
	
	public func RAW_encode(dest: UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
		var dest = sig.RAW_encode(dest: dest)
		dest = unsignedEvent.RAW_encode(dest: dest)
		return dest
	}
}

extension NOSTR_event_signed {
	/// Validation of a `NOSTR_event_signed` uses the authors `PublicKey`.
	/// Validation occurs whenever the event is being read from storage.
	public func isValidSignature() -> Bool {
		sig.RAW_access_staticbuff { sigPtr in
			unsignedEvent.id.RAW_access { msgPtr in
				Ed25519.verify(signature: sigPtr, publicKey: unsignedEvent.publicKey, message: msgPtr)
			}
		}
	}
}
