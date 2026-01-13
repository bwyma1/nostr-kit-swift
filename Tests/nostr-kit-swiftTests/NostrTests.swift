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
		let tags: [EventTag]
		let date:NOSTR_date
		let kind:NOSTR_kind
		let publicKey:PublicKey
		let privateKey:MemoryGuarded<Ed25519.PrivateKey>
		let content:StringContent
		let event:UnsignedEvent<StringContent>
			
		init() throws {
			let tagName = NOSTR_tag_name(RAW_staticbuff: [0,1,2,3])
			let tagValue1 = NOSTR_tag_generic_value(stringLiteral: "This is an example of a tag value. The first tag value example. ")
			let tagValue2 = NOSTR_tag_generic_value(stringLiteral: "Another tag example.")
			var tagValues = [tagValue1]
			let tag = try EventTag(NOSTR_tag_index_field: tagName, NOSTR_tag_values: tagValues)
			tagValues = [tagValue1, tagValue2]
			let tag2 = try EventTag(NOSTR_tag_index_field: tagName, NOSTR_tag_values: tagValues)
			tags = [tag, tag2]
			(publicKey, privateKey) = try Ed25519.generateKeys(secretKey: NostrEventTests.staticPrivateKey)
			date = try generateSecureRandomBytes(as: NOSTR_date.self)
			kind = NOSTR_kind(RAW_native: 1)
			content = StringContent(stringLiteral: "Some Nostr Content")
			event = try UnsignedEvent(publicKey: publicKey, date: date, tags: [tag, tag2], kind: kind, content: content)
		}
		
		@Test func encodeDecodeTag() throws {
			let tag = tags[1]
			var tagLen = 0; tag.RAW_encode(count: &tagLen)
			let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: tagLen)
			defer { buffer.deallocate() }
			_ = tag.RAW_encode(dest:buffer.baseAddress!)
			let decodedTag = EventTag(RAW_decode: buffer.baseAddress!, count: tagLen)!
			#expect(tag.isEqual(to: decodedTag))
		}
		
		@Test func encodeDecodeEvent() throws {
			var eventLen = 0; event.RAW_encode(count: &eventLen)
			let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: eventLen)
			defer { buffer.deallocate() }
			_ = event.RAW_encode(dest:buffer.baseAddress!)
			let decodedEvent = UnsignedEvent<StringContent>(RAW_decode: buffer.baseAddress!, count: eventLen)!
			#expect(event.id == decodedEvent.id)
			#expect(event.publicKey == decodedEvent.publicKey)
			#expect(event.date == decodedEvent.date)
			#expect(event.tags as! [EventTag] == decodedEvent.tags as! [EventTag])
			#expect(event.kind == decodedEvent.kind)
			#expect(event.content == decodedEvent.content)
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
			#expect(try signedEvent.isValidSignature())
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
			let filter = Filter(ids: [event.id], authors: [event.publicKey], kinds: [event.kind], tags: tags, since: since, until: until)
			var filterLen = 0; filter.RAW_encode(count: &filterLen)
			let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: filterLen)
			defer { buffer.deallocate() }
			_ = filter.RAW_encode(dest:buffer.baseAddress!)
			let decodedFilter = Filter(RAW_decode: buffer.baseAddress!, count: filterLen)!
			#expect(filter.ids == decodedFilter.ids)
			#expect(filter.authors == decodedFilter.authors)
			#expect(filter.kinds == decodedFilter.kinds)
			#expect(filter.tags as! [EventTag] == decodedFilter.tags as! [EventTag])
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
			#expect(nilFilter.tags as! [EventTag] == decodedNilFilter.tags as! [EventTag])
			#expect(decodedNilFilter.since == nil)
			#expect(nilFilter.until == decodedNilFilter.until)
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
		
		
	}
}

extension NostrTests {
	@Suite("Nostr Event Tests",
		   .serialized
	)
	
	struct NostrMessageTests {
		@Test func encodeDecodeREQMessage() throws {
			let reqFilter = Filter(ids: [], authors: [], kinds: [], tags: [], since: nil, until: nil)
			let filters = [reqFilter, reqFilter]
			let reqMessage = NOSTR_message_REQ(subscriptionID: "home", filters: filters)
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
