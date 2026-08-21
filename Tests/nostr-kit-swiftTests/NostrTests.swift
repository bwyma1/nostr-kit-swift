import Testing
import Foundation
@testable import nostr_kit_swift
import RAW_ed25519
import RAW_dh25519
import RAW_base64
import RAW

@Suite("nostr tests", .serialized)
struct NostrTests { }

extension NostrTests {
	@Suite("Nostr Event Tests",
		.serialized
	)
	struct NostrEventTests {
		static let staticPrivateKey = MemoryGuarded<PrivateKey>(RAW_decode:try! RAW_base64.decode("8DFnI7tPWLl4WmuEp4T5KVuKMW6iyjRdTb3IVaDe+kI="), count:32)!
		let tags: [any NOSTR_tag]
		let date:NOSTR_date
		let application:NOSTR_application
		let kind:NOSTR_kind
		let publicKey:PublicKey
		let privateKey:MemoryGuarded<Ed25519.PrivateKey>
		let content:StringContent
		let event:UnsignedEvent<StringContent>
		
		init() throws {
			let tag = StringTag(name: "e", value: "val1")!
			let tag2 = StringTag(name: "e", value: "val2")!
			let tag3 = StringTag(name: "p", value: "val3")!
			tags = [tag, tag2, tag3]
			(publicKey, privateKey) = try Ed25519.generateKeys(secretKey: NostrEventTests.staticPrivateKey)
			date = NOSTR_date(date: Date())
			application = NOSTR_application(RAW_native: 2)
			kind = NOSTR_kind(RAW_native: 1)
			content = StringContent(stringLiteral: "Some Nostr Content")
			event = try UnsignedEvent(publicKey: publicKey, date: date, tags: [tag, tag2], application: application, kind: kind, content: content)
		}
		
		@Test func encodeDecodeTag() throws {
			let tag = tags[1]
			var tagLen = 0; tag.RAW_encode(count: &tagLen)
			let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: tagLen)
			defer { buffer.deallocate() }
			_ = tag.RAW_encode(dest:buffer.baseAddress!)
			let decodedTag = EventTag(RAW_decode: buffer.baseAddress!, count: tagLen)!
			#expect(tag.indexField == decodedTag.indexField && tag.value.isEqual(to: decodedTag.value))
		}
		
		@Test func encodeDecodeEvent() throws {
			var eventLen = 0; event.RAW_encode(count: &eventLen)
			let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: eventLen)
			defer { buffer.deallocate() }
			_ = event.RAW_encode(dest:buffer.baseAddress!)
			let decodedEvent = UnsignedEvent<StringContent>(RAW_decode: buffer.baseAddress!, count: eventLen)!
			#expect(event == decodedEvent)
		}
		
		@Test func encodeDecodeSignedEvent() throws {
			let signedEvent = try event.sign(as: privateKey)
			var eventLen = 0; signedEvent.RAW_encode(count: &eventLen)
			let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: eventLen)
			defer { buffer.deallocate() }
			_ = signedEvent.RAW_encode(dest:buffer.baseAddress!)
			let decodedSignedEvent = NOSTR_event_signed<UnsignedEvent<StringContent>>(RAW_decode: buffer.baseAddress!, count: eventLen)!
			#expect(decodedSignedEvent.isValidSignature())
		}
		
		@Test func signAndVerifyEvent() throws {
			let signedEvent = try event.sign(as: privateKey)
			#expect(signedEvent.isValidSignature())
		}
		
		@Test func signedEventRAWaccess() throws {
			let signedEvent = try event.sign(as: privateKey)
			var eventLen = 0; signedEvent.RAW_encode(count: &eventLen)
			let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: eventLen)
			defer { buffer.deallocate() }
			_ = signedEvent.RAW_encode(dest:buffer.baseAddress!)
			signedEvent.RAW_access { ptr in
				#expect(ptr.count == buffer.count)
				#expect(memcmp(ptr.baseAddress!, buffer.baseAddress!, buffer.count) == 0)
			}
		}
		
		@Test func encodeDecodeFilter() throws {
			let since = NOSTR_date(0)
			let until = NOSTR_date(1000)
			let filter = Filter(ids: [event.id], authors: [event.publicKey], applications: [application], kinds: [event.kind], tags: tags, since: since, until: until)
			var filterLen = 0; filter.RAW_encode(count: &filterLen)
			let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: filterLen)
			defer { buffer.deallocate() }
			_ = filter.RAW_encode(dest:buffer.baseAddress!)
			let decodedFilter = Filter(RAW_decode: buffer.baseAddress!, count: filterLen)!
			#expect(filter.ids == decodedFilter.ids)
			#expect(filter.authors == decodedFilter.authors)
			#expect(filter.kinds == decodedFilter.kinds)
			for i in (0..<filter.tags.count) {
				let t1 = filter.tags[i]
				let t2 = decodedFilter.tags[i]
				#expect(t1.indexField == t2.indexField && t1.value.isEqual(to: t2.value))
			}
			#expect(filter.since == decodedFilter.since)
			#expect(filter.until == decodedFilter.until)
		
			let nilFilter = Filter(ids: [event.id], authors: [], kinds: [event.kind], tags: tags, since: nil, until: until)
			filterLen = 0; nilFilter.RAW_encode(count: &filterLen)
			let nilBuffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: filterLen)
			defer { nilBuffer.deallocate() }
			_ = nilFilter.RAW_encode(dest:nilBuffer.baseAddress!)
			let decodedNilFilter = Filter(RAW_decode: nilBuffer.baseAddress!, count: filterLen)!
			#expect(nilFilter.ids == decodedNilFilter.ids)
			#expect(decodedNilFilter.authors.isEmpty)
			#expect(nilFilter.kinds == decodedNilFilter.kinds)
			for i in (0..<filter.tags.count) {
				let t1 = filter.tags[i]
				let t2 = decodedFilter.tags[i]
				#expect(t1.indexField == t2.indexField && t1.value.isEqual(to: t2.value))
			}
			#expect(decodedNilFilter.since == nil)
			#expect(nilFilter.until == decodedNilFilter.until)
		}

		@Test func truncatedFilterDecodeRejectsOutOfBounds() throws {
			// Regression test for H1: the filter decoder must not read past the buffer.
			// A valid filter is encoded, then truncated at every byte boundary. The decoder
			// must either decode successfully (for complete prefixes) or return nil —
			// never crash or over-read.
			let filter = Filter(ids: [event.id], authors: [event.publicKey], applications: [application], kinds: [event.kind], tags: tags, since: NOSTR_date(0), until: NOSTR_date(1000))
			var filterLen = 0; filter.RAW_encode(count: &filterLen)
			let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: filterLen)
			defer { buffer.deallocate() }
			_ = filter.RAW_encode(dest: buffer.baseAddress!)

			for cut in 0..<filterLen {
				// Simulate a truncated wire message: only the first `cut` bytes arrive.
				let truncated = Filter(RAW_decode: buffer.baseAddress!, count: cut)
				// Accepting a short-but-valid prefix is fine; it must simply not crash.
				_ = truncated
			}

			// A filter that claims more tags/ids than are present must be rejected.
			var overlong = [UInt8](buffer)
			// The ids count byte (first byte) claims 1 id is present. Rewrite it to claim
			// 255 ids — far more than the buffer can hold. The decoder must reject it.
			overlong[0] = 255
			let rejected = Filter(RAW_decode: overlong, count: overlong.count)
			#expect(rejected == nil)
		}
		
		@Test func encodeDecodeEVENTMessage() throws {
			let signedEvent = try event.sign(as: privateKey)
			let eventMessage = NOSTR_message_EVENT(subscriptionID: "home", event: signedEvent)
			var messageLen: Int = 0; eventMessage.RAW_encode(count: &messageLen)
			let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: messageLen)
			defer { buffer.deallocate() }
			_ = eventMessage.RAW_encode(dest:buffer.baseAddress!)
			let decodedEventMessage = NOSTR_message_EVENT<UnsignedEvent<StringContent>>(RAW_decode: buffer.baseAddress!, count: messageLen)!
			#expect(eventMessage.type == decodedEventMessage.type)
			#expect(eventMessage.event.id == decodedEventMessage.event.id)
			#expect(decodedEventMessage.event.isValidSignature())
		}
		
		@Test func applyPositiveFilters() throws {
			let signedEvent = try event.sign(as: privateKey)
			let tags:[any NOSTR_tag] = [StringTag(name: "e", value: "val1")!, StringTag(name: "e", value: "val2")!]
			let filter = Filter(ids: [event.id], authors: [event.publicKey], kinds: [event.kind], tags: tags)
			#expect(filter.apply(to: signedEvent))
		}
		
		@Test func applyNegativeFilters() throws {
			let signedEvent = try event.sign(as: privateKey)
			var tags:[any NOSTR_tag] = [StringTag(name: "e", value: "val2")!, StringTag(name: "e", value: "val4")!]
			let filterTags = Filter(ids: [event.id], authors: [event.publicKey], kinds: [event.kind], tags: tags)
			#expect(!filterTags.apply(to: signedEvent))
			
			tags = []
			let filterKind = Filter(ids: [event.id], authors: [event.publicKey], kinds: [NOSTR_kind(RAW_native:2)], tags: tags)
			#expect(!filterKind.apply(to: signedEvent))
		}
	}
}

extension NostrTests {
	@Suite("Event Validation Tests",
		   .serialized
	)
	struct NostrEventValidationTests {
		static let staticPrivateKey = MemoryGuarded<PrivateKey>(RAW_decode:try! RAW_base64.decode("8DFnI7tPWLl4WmuEp4T5KVuKMW6iyjRdTb3IVaDe+kI="), count:32)!
		let tags: [any NOSTR_tag]
		let date: NOSTR_date
		let application: NOSTR_application
		let kind: NOSTR_kind
		let publicKey: PublicKey
		let privateKey: MemoryGuarded<Ed25519.PrivateKey>
		let content: StringContent
		let event: UnsignedEvent<StringContent>

		init() throws {
			let tag = StringTag(name: "e", value: "val1")!
			tags = [tag]
			(publicKey, privateKey) = try Ed25519.generateKeys(secretKey: NostrEventValidationTests.staticPrivateKey)
			date = NOSTR_date(date: Date())
			application = NOSTR_application(RAW_native: 2)
			kind = NOSTR_kind(RAW_native: 1)
			content = StringContent(stringLiteral: "Some Nostr Content")
			event = try UnsignedEvent(publicKey: publicKey, date: date, tags: [tag], application: application, kind: kind, content: content)
		}

		@Test func validEventIsValid() throws {
			#expect(event.isValid())
		}

		@Test func isValidSignatureRejectsIdMismatch() throws {
			let signedEvent = try event.sign(as: privateKey)
			// A signature that is valid over the stored id must still be rejected if the
			// stored id does not match the recomputed hash of the fields.
			var wrongID = signedEvent.unsignedEvent.id
			wrongID.RAW_access_mutating { ptr in
				ptr.baseAddress![0] ^= 0xFF
			}
			let badEvent = UnsignedEvent(id: wrongID, publicKey: publicKey, date: date, tags: tags, application: application, kind: kind, content: content)
			let tampered = NOSTR_event_signed(unsignedEvent: badEvent, sig: signedEvent.sig)
			#expect(!tampered.isValidSignature())
		}

		@Test func signRejectsEventWithWrongID() throws {
			var wrongID = event.id
			wrongID.RAW_access_mutating { ptr in
				ptr.baseAddress![0] ^= 0xFF
			}
			let badEvent = UnsignedEvent(id: wrongID, publicKey: publicKey, date: date, tags: tags, application: application, kind: kind, content: content)
			#expect(throws: NOSTR_event_error.self) {
				try badEvent.sign(as: privateKey)
			}
		}

		@Test func signRejectsTagWithNilName() throws {
			// Encode a valid tag, then corrupt its 8-byte indexField with bytes that
			// are not valid UTF-8 so `tag.name` decodes to nil (violating the rule
			// that every tag must have a name of at least one character).
			let validTag = StringTag(name: "e", value: "val1")!
			var tagLen = 0; validTag.RAW_encode(count: &tagLen)
			var tagBuf = [UInt8](repeating: 0, count: tagLen)
			_ = validTag.RAW_encode(dest: &tagBuf)
			for i in 0..<MemoryLayout<NOSTR_tag_name>.size {
				tagBuf[i] = 0xFF
			}
			let badTag = EventTag(RAW_decode: tagBuf, count: tagBuf.count)!
			#expect(badTag.name == nil)
			let badEvent = try UnsignedEvent(publicKey: publicKey, date: date, tags: [badTag], application: application, kind: kind, content: content)
			#expect(!badEvent.isValid())
			#expect(throws: NOSTR_event_error.self) {
				try badEvent.sign(as: privateKey)
			}
		}

		@Test func throwingRAWaccessBodyDoesNotCrash() throws {
			// Regression test for H2: a `RAW_access` body that throws must propagate the
			// error (re-thrown as its typed `E`), NOT crash the process via `try!`.
			let tag = StringTag(name: "e", value: "val1")!
			do {
				try tag.RAW_access { (_: UnsafeBufferPointer<UInt8>) throws -> Void in
					throw NOSTR_event_error.eventValidationFailed
				}
				Issue.record("expected a thrown error from RAW_access body")
			} catch NOSTR_event_error.eventValidationFailed {
				// Expected: the error propagated rather than crashing.
			} catch {
				Issue.record("unexpected error type: \(error)")
			}
		}

		@Test func throwingRAWaccessMutatingBodyDoesNotCrash() throws {
			// Same for `RAW_access_mutating`: a throwing body must propagate the typed
			// error rather than crashing via `try!`.
			var tag = StringTag(name: "e", value: "val1")!
			do {
				try tag.RAW_access_mutating { (_: UnsafeMutableBufferPointer<UInt8>) throws -> Void in
					throw NOSTR_event_error.eventValidationFailed
				}
				Issue.record("expected a thrown error from RAW_access_mutating body")
			} catch NOSTR_event_error.eventValidationFailed {
				// Expected.
			} catch {
				Issue.record("unexpected error type: \(error)")
			}
		}
	}
}

extension NostrTests {
	@Suite("Tag Name Tests",
		   .serialized
	)
	struct NostrTagNameTests {
		@Test func initRejectsNameLongerThanEightBytes() {
			#expect(NOSTR_tag_name(string: "e") != nil)
			#expect(NOSTR_tag_name(string: "12345678") != nil)  // exactly 8 bytes
			#expect(NOSTR_tag_name(string: "123456789") == nil)  // 9 bytes
			// Multi-byte characters count in UTF-8 bytes, not characters.
			#expect(NOSTR_tag_name(string: "éééé") != nil)  // 4 × 2 = 8 bytes
			#expect(NOSTR_tag_name(string: "ééééé") == nil)  // 5 × 2 = 10 bytes
		}

		@Test func shortNameRoundTripsWithoutGarbageTail() throws {
			let name = NOSTR_tag_name(string: "e")!
			// The 8-byte field is NUL-padded, so `.string` decodes cleanly to "e"
			// (no trailing garbage or zero bytes).
			#expect(name.string == "e")

			var len = 0; name.RAW_encode(count: &len)
			#expect(len == MemoryLayout<NOSTR_tag_name>.size)
			let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: len)
			defer { buffer.deallocate() }
			_ = name.RAW_encode(dest: buffer.baseAddress!)
			var readPtr = UnsafeRawPointer(buffer.baseAddress!)
			let decoded = NOSTR_tag_name(RAW_staticbuff_seeking: &readPtr)
			#expect(decoded == name)
			#expect(decoded.string == "e")
		}

		@Test func genericTagRejectsOverlongName() {
			#expect(StringTag(name: "expiration", value: "2026") == nil)
			#expect(StringTag(name: "e", value: "val1") != nil)
		}

		@Test func emptyNameDecodesToEmptyString() {
			// An all-NUL 8-byte field represents an empty name.
			let zeroes = [UInt8](repeating: 0, count: MemoryLayout<NOSTR_tag_name>.size)
			let name = zeroes.withUnsafeBytes { NOSTR_tag_name(RAW_staticbuff: $0.baseAddress!) }
			#expect(name.string == "")
		}

		@Test func tagsEqualityAndHashAreByteLevel() throws {
			// M1/M2 regression: `NOSTR_tags` equality must be byte-level (not via
			// `hashValue`/`AnyHashable`), and hashing must be consistent with that
			// equality so the Hashable contract holds.

			// Two tags wrapping identical bytes but as DIFFERENT concrete types.
			let generic = StringTag(name: "e", value: "val1")!
			// Encode the generic tag, then decode it as the generic EventTag — same bytes.
			var tagLen = 0; generic.RAW_encode(count: &tagLen)
			let tagBuffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: tagLen)
			defer { tagBuffer.deallocate() }
			_ = generic.RAW_encode(dest: tagBuffer.baseAddress!)
			let decodedEventTag = EventTag(RAW_decode: tagBuffer.baseAddress!, count: tagLen)!

			// Byte-level equality: different concrete types, same bytes ⇒ equal.
			#expect(generic.isEqual(to: decodedEventTag))

			let lhs = NOSTR_tags(array: [generic])
			let rhs = NOSTR_tags(array: [decodedEventTag])
			#expect(lhs == rhs)

			// Equal ⇒ equal hash (Hashable contract).
			#expect(lhs.hashValue == rhs.hashValue)

			// Consistent Set/Dictionary keying.
			var set: Set<NOSTR_tags> = [lhs]
			#expect(set.contains(rhs))
			set.insert(rhs)
			#expect(set.count == 1)

			// A genuinely different tag is neither equal nor equal-hashing.
			let other = StringTag(name: "e", value: "different")!
			let otherTags = NOSTR_tags(array: [other])
			#expect(lhs != otherTags)
			#expect(!set.contains(otherTags))
		}
		}
}

extension NostrTests {
	@Suite("Nostr Event Tests",
		   .serialized
	)
	
	struct NostrMessageTests {
		@Test func encodeDecodeREQMessage() throws {
			let reqFilter = Filter()
			let filters = [reqFilter, reqFilter]
			let reqMessage = NOSTR_message_REQ(subscriptionID: "home", filters: filters, from: PublicKey(privateKey: NostrEventTests.staticPrivateKey), fetchHistory: false)
			var reqLen = 0; reqMessage.RAW_encode(count: &reqLen)
			let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: reqLen)
			defer { buffer.deallocate() }
			_ = reqMessage.RAW_encode(dest:buffer.baseAddress!)
			let decodedReqMessage = NOSTR_message_REQ(RAW_decode: buffer.baseAddress!, count: reqLen)!
			#expect(decodedReqMessage.subscriptionID == reqMessage.subscriptionID)
			#expect(decodedReqMessage.type == reqMessage.type)
		}
		
		@Test func encodeDecodeEOSEMessage() throws {
			let eoseMessage = NOSTR_message_EOSE(subscriptionID: "home")
			var eoseLen = 0; eoseMessage.RAW_encode(count: &eoseLen)
			let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: eoseLen)
			defer { buffer.deallocate() }
			_ = eoseMessage.RAW_encode(dest:buffer.baseAddress!)
			let decodedEoseMessage = NOSTR_message_EOSE(RAW_decode: buffer.baseAddress!, count: eoseLen)!
			#expect(decodedEoseMessage.subscriptionID == eoseMessage.subscriptionID)
			#expect(decodedEoseMessage.type == eoseMessage.type)
		}
		
		@Test func encodeDecodeCLOSEMessage() throws {
			let closeMessage = NOSTR_message_CLOSE(subscriptionID: "home")
			var closeLen = 0; closeMessage.RAW_encode(count: &closeLen)
			let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: closeLen)
			defer { buffer.deallocate() }
			_ = closeMessage.RAW_encode(dest:buffer.baseAddress!)
			let decodedCloseMessage = NOSTR_message_CLOSE(RAW_decode: buffer.baseAddress!, count: closeLen)!
			#expect(decodedCloseMessage.subscriptionID == closeMessage.subscriptionID)
			#expect(decodedCloseMessage.type == closeMessage.type)
		}
		
		@Test func encodeDecodeNOTICEMessage() throws {
			let noticeMessage = NOSTR_message_NOTICE(noticeText: "Hello World!")
			var noticeLen = 0; noticeMessage.RAW_encode(count: &noticeLen)
			let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: noticeLen)
			defer { buffer.deallocate() }
			_ = noticeMessage.RAW_encode(dest:buffer.baseAddress!)
			let decodedNoticeMessage = NOSTR_message_NOTICE(RAW_decode: buffer.baseAddress!, count: noticeLen)!
			#expect(decodedNoticeMessage.noticeText == noticeMessage.noticeText)
			#expect(decodedNoticeMessage.type == noticeMessage.type)
		}
		
		@Test func encodeDecodeOKMessage() throws {
			let eventID = try generateSecureRandomBytes(as: NOSTR_id.self)
			let okMessage = NOSTR_message_OK(eventID:eventID, status:true)
			var okLen = 0; okMessage.RAW_encode(count: &okLen)
			let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: okLen)
			defer { buffer.deallocate() }
			_ = okMessage.RAW_encode(dest:buffer.baseAddress!)
			let decodedOkMessage = NOSTR_message_OK(RAW_decode: buffer.baseAddress!, count: okLen)!
			#expect(decodedOkMessage.type == okMessage.type)
		}
	}
}
