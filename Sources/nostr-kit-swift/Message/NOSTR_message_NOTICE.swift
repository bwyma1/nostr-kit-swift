import RAW

@RAW_convertible_string_type<UTF8>(backing:RAW_byte.self)
fileprivate struct NoticeText: NOSTR_event_content, Comparable, ExpressibleByStringLiteral { }

/// A signal with an attached text sent by the server to the client.
///
/// Can be a warning or other relevant information.
public struct NOSTR_message_NOTICE:Sendable, RAW_convertible {
	
	let type:NOSTR_message_type = NOSTR_message_type(RAW_native:0x104)
	
	fileprivate let text:NoticeText
	
	/// The notice text as a Swift `String`.
	public var noticeText:String { String(text) }
	
	/// Creates a NOTICE message with the given text.
	public init(noticeText:String) {
		self.text = NoticeText(stringLiteral: noticeText)
	}
	
	public init?(RAW_decode inputPtr:consuming UnsafeRawPointer, count: RAW.size_t) {
		guard count >= MemoryLayout<Bytes4>.size else { return nil }
		let textLength = Int(Bytes4(RAW_staticbuff_seeking: &inputPtr).RAW_native())
		var dataCount = count - MemoryLayout<Bytes4>.size
		guard dataCount >= textLength else { return nil }
		self.text = NoticeText(RAW_decode: inputPtr, count: textLength)
		inputPtr = inputPtr.advanced(by: textLength)
		dataCount -= textLength
		
		guard dataCount >= MemoryLayout<NOSTR_message_type>.size else { return nil }
		let readType = NOSTR_message_type(RAW_staticbuff_seeking: &inputPtr)
		guard readType.RAW_native() == 0x104 else { return nil }
	}
	
	public func RAW_encode(count: inout RAW.size_t) {
		text.RAW_encode(count: &count)
		count += MemoryLayout<NOSTR_message_type>.size + MemoryLayout<Bytes4>.size
	}
	
	public func RAW_encode(dest: UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
		var textLength = 0; text.RAW_encode(count: &textLength)
		let textLengthBytes = Bytes4(RAW_native: UInt32(textLength))
		var dest = textLengthBytes.RAW_encode(dest: dest)
		dest = text.RAW_encode(dest: dest)
		
		return type.RAW_encode(dest: dest)
	}
}
