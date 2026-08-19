import Testing
@testable import nostr_kit_swift
import Foundation
import RAW
import ContentMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosGenericTestSupport

@NostrTag(name: "d")
struct DTag: Sendable, Hashable, Equatable, NOSTR_tag {
	var indexField = NOSTR_tag_name(string: "d")
	var value: NOSTR_id
	init(value: NOSTR_id) throws {
		self.value = value
	}
}

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

let testMacros: [String: MacroSpec] = [
	"NostrContent": .init(type: NostrContent.self)
]

extension NostrTests {
	@Suite("Nostr Macro Tests",
		   .serialized
	)
	struct NostrMacroTests {
		
		@Test func testMacro() {
			assertMacroExpansion(
				"""
				@NostrContent
				struct SomeContent: Sendable, Equatable, Hashable {
					public var content: EncodedBool
				}
				""",
				expandedSource: """
				struct SomeContent: Sendable, Equatable, Hashable {
					public var content: EncodedBool
				
				    public init(content: EncodedBool) {
				        self.content = content
				    }
				
				    public init(contentNative: Bool) {
				        self.content = EncodedBool(contentNative)
				    }
				}

				extension SomeContent: RAW_convertible {
					public init?(RAW_decode inputPtr: consuming UnsafeRawPointer, count: RAW.size_t) {
					    var inputPtr = inputPtr
					    var dataCount = count
					    guard dataCount >= MemoryLayout<EncodedBool>.size else {
					        return nil
					    }
					    let content0 = EncodedBool(RAW_staticbuff_seeking: &inputPtr)
					    dataCount -= MemoryLayout<EncodedBool>.size
					    self.content = content0
					    guard dataCount == 0 else {
					        return nil
					    }
					}
					public func RAW_encode(count: inout RAW.size_t) {
					    content.RAW_encode(count: &count)
					}
					public func RAW_encode(dest: UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
					    var dest = dest
					    dest = content.RAW_encode(dest: dest)
					    return dest
					}
				}
				""",
				macroSpecs: testMacros
			) { failure in
				Issue.record(
					"\(failure.message)",
					sourceLocation: .init(
						fileID: failure.location.fileID,
						filePath: failure.location.filePath,
						line: failure.location.line,
						column: failure.location.column
					)
				)
			}
		}
		
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
		
		@Test func encodeDecodeTag() throws {
			let nostrId = try generateSecureRandomBytes(as: NOSTR_id.self)
			let content = try DTag(value: nostrId)
			var contentLen: Int = 0; content.RAW_encode(count: &contentLen)
			let bufferA = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: contentLen)
			defer { bufferA.deallocate() }
			_ = content.RAW_encode(dest:bufferA.baseAddress!)
			let decodedContent = DTag(RAW_decode: bufferA.baseAddress!, count: contentLen)!
			#expect(content == decodedContent)
		}
	}
}
