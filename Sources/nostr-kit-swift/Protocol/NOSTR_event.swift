import Foundation
import RAW
import RAW_dh25519
import RAW_sha256
import RAW_ed25519

public protocol NOSTR_event_content: Sendable, Hashable, RAW_convertible { }

public protocol NOSTR_event_unsigned: Sendable, Hashable, Identifiable, RAW_convertible {
	
	var id:NOSTR_id { get }
	
	var publicKey:PublicKey { get set }
	
	var date:NOSTR_date { get set }
	
	var tags:NOSTR_tags { get set }
	
	var application:NOSTR_application { get set }
	
	var kind:NOSTR_kind { get set }
	
	associatedtype ContentType:NOSTR_event_content
	var content:ContentType { get set }
	
	init(id:NOSTR_id, publicKey:PublicKey, date:NOSTR_date, tags:[any NOSTR_tag], application:NOSTR_application, kind:NOSTR_kind, content:ContentType)
}

extension NOSTR_event_unsigned {
	public init(publicKey:PublicKey, date:NOSTR_date, tags:[any NOSTR_tag], application:NOSTR_application, kind:NOSTR_kind, content:ContentType) throws {
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
		try hasher.update(application)
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
		
		self = Self(id: id, publicKey: publicKey, date: date, tags: tags, application: application, kind: kind, content: content)
	}
	
	public init(publicKey:PublicKey, tags:[any NOSTR_tag], application:NOSTR_application, kind:NOSTR_kind, content:ContentType) throws {
		let date = NOSTR_date(date: Date())
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
		try hasher.update(application)
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
		
		self = Self(id: id, publicKey: publicKey, date: date, tags: tags, application: application, kind: kind, content: content)
	}
	
	public init(publicKey:PublicKey, date:NOSTR_date = NOSTR_date(date: Date()), tags:[any NOSTR_tag], application:UInt16, kind:UInt32, content:ContentType) throws {
		let kind = NOSTR_kind(RAW_native: kind)
		let application = NOSTR_application(RAW_native: application)
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
		try hasher.update(application)
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
		
		self = Self(id: id, publicKey: publicKey, date: date, tags: tags, application: application, kind: kind, content: content)
	}
}

extension NOSTR_event_unsigned {
	/// Sign the `NOSTR_event_unsigned` using the authors `PrivateKey`.
	/// The event should only ever be signed once.
	/// The event should be signed once it has been confirmed to be finalized.
	public func sign(as author:MemoryGuarded<Ed25519.PrivateKey>) throws -> NOSTR_event_signed<Self> {
		var sig = NOSTR_sig(RAW_staticbuff: NOSTR_sig.RAW_staticbuff_zeroed())
		sig.RAW_access_mutating { sigPtr in
			id.RAW_access { msgPtr in
				Ed25519.sign(signature: sigPtr.baseAddress!, privateKey: author, message: msgPtr)
			}
		}
		return NOSTR_event_signed(unsignedEvent: self, sig: sig)
	}
}

public struct NOSTR_event_signed<UnsignedEvent:NOSTR_event_unsigned>: Sendable, Hashable, Identifiable, RAW_convertible, RAW_accessible {
	public let sig:NOSTR_sig
	// For identifiable protocol
	public var id: NOSTR_sig {
		sig
	}
	
	public let unsignedEvent:UnsignedEvent
	
	public init(unsignedEvent:UnsignedEvent, sig:NOSTR_sig) {
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
