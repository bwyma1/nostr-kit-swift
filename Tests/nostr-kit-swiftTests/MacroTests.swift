import Testing
@testable import nostr_kit_swift
import Foundation
import RAW

@NostrContent
struct BasicContent: Sendable, Equatable, Hashable {
	public var variableA: EncodedBool
	public var variableB: EncodedString?
}

@NostrContent
struct ComplexContent: Sendable, Equatable, Hashable {
	public var content: [BasicContent]?
	public var dictContent: [EncodedString: [EncodedUInt16?]]?
}

extension NostrTests {
	@Suite("Nostr Macro Tests",
		   .serialized
	)
	struct NostrMacroTests {
		@Test func encodeDecodeBasicContent() throws {
			var content = BasicContent(variableA: EncodedBool(true), variableB: EncodedString("Hello World"))
			var contentLen: Int = 0; content.RAW_encode(count: &contentLen)
			let bufferA = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: contentLen)
			defer { bufferA.deallocate() }
			_ = content.RAW_encode(dest:bufferA.baseAddress!)
			var decodedContent = BasicContent(RAW_decode: bufferA.baseAddress!, count: contentLen)!
			#expect(content == decodedContent)
			
			content = BasicContent(variableA: EncodedBool(false), variableB: nil)
			contentLen = 0; content.RAW_encode(count: &contentLen)
			let bufferB = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: contentLen)
			defer { bufferB.deallocate() }
			_ = content.RAW_encode(dest:bufferB.baseAddress!)
			decodedContent = BasicContent(RAW_decode: bufferB.baseAddress!, count: contentLen)!
			#expect(content == decodedContent)
		}
		
		@Test func encodeDecodeComplexContent() throws {
			let dictContent: [EncodedString: [EncodedUInt16?]]? = [
				EncodedString("first"): [EncodedUInt16(1), EncodedUInt16(2), nil],
				EncodedString("second"): [nil, EncodedUInt16(42)]
			]
			let content = ComplexContent(
				content: [
					BasicContent(variableA: EncodedBool(true), variableB: EncodedString("Hello World")),
					BasicContent(variableA: EncodedBool(false), variableB: nil),
				],
				dictContent: dictContent
				)
			var contentLen: Int = 0; content.RAW_encode(count: &contentLen)
			let bufferA = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: contentLen)
			defer { bufferA.deallocate() }
			_ = content.RAW_encode(dest:bufferA.baseAddress!)
			let decodedContent = ComplexContent(RAW_decode: bufferA.baseAddress!, count: contentLen)!
			#expect(content == decodedContent)
		}
	}
}
