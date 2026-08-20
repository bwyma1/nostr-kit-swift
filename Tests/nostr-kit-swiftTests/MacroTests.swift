import Testing
@testable import nostr_kit_swift
import Foundation
import RAW
import ContentMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosGenericTestSupport

@NostrTag(name: "d", valueType: NOSTR_id.self)
struct DTag: Sendable, Hashable, Equatable, NOSTR_tag {}

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
	"NostrContent": .init(type: NostrContent.self),
	"NostrTag": .init(type: NostrTag.self)
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

		@Test func tagNameEmptyIsACompileError() {
			assertMacroExpansion(
				"""
				@NostrTag(name: "")
				struct EmptyTag: Sendable, Hashable, Equatable, NOSTR_tag {
					var indexField: NOSTR_tag_name
					var value: EncodedString
				}
				""",
				expandedSource: """
				struct EmptyTag: Sendable, Hashable, Equatable, NOSTR_tag {
					var indexField: NOSTR_tag_name
					var value: EncodedString
				}
				""",
				diagnostics: [
					DiagnosticSpec(
						message: "@NostrTag name must not be empty; a tag requires a name of at least one character.",
						line: 1,
						column: 1
					)
				],
				macroSpecs: testMacros
			) { failure in
				Issue.record(
					"\\(failure.message)",
					sourceLocation: .init(
						fileID: failure.location.fileID,
						filePath: failure.location.filePath,
						line: failure.location.line,
						column: failure.location.column
					)
				)
			}
		}

		@Test func tagNameOverEightBytesIsACompileError() {
			assertMacroExpansion(
				"""
				@NostrTag(name: "expiration")
				struct ExpTag: Sendable, Hashable, Equatable, NOSTR_tag {
					var indexField: NOSTR_tag_name
					var value: EncodedString
				}
				""",
				expandedSource: """
				struct ExpTag: Sendable, Hashable, Equatable, NOSTR_tag {
					var indexField: NOSTR_tag_name
					var value: EncodedString
				}
				""",
				diagnostics: [
					DiagnosticSpec(
						message: "@NostrTag name \"expiration\" is 10 UTF-8 bytes; the tag-name wire field holds at most 8 bytes. Shorten the name.",
						line: 1,
						column: 1
					)
				],
				macroSpecs: testMacros
			) { failure in
				Issue.record(
					"\\(failure.message)",
					sourceLocation: .init(
						fileID: failure.location.fileID,
						filePath: failure.location.filePath,
						line: failure.location.line,
						column: failure.location.column
					)
				)
			}
		}

		@Test func memberMacroGeneratesValueAndInit() {
			assertMacroExpansion(
				"""
				@NostrTag(name: "d", valueType: NOSTR_id.self)
				struct DTag: Sendable, Hashable, Equatable, NOSTR_tag {
				}
				""",
				expandedSource: """
				struct DTag: Sendable, Hashable, Equatable, NOSTR_tag {

				    public var indexField = NOSTR_tag_name(string: "d")!

				    public var value: NOSTR_id

				    public init(value: NOSTR_id) {
				        self.value = value
				    }
				}

				extension DTag: RAW_convertible {
					public init?(RAW_decode inputPtr: consuming UnsafeRawPointer, count: RAW.size_t) {
					var dataCount = count
					guard dataCount >= MemoryLayout<NOSTR_tag_name>.size else {
					    return nil
					}

					self.indexField = NOSTR_tag_name(RAW_staticbuff_seeking: &inputPtr)
					dataCount -= MemoryLayout<NOSTR_tag_name>.size
					guard indexField == NOSTR_tag_name(string: "d")! else {
					    return nil
					}

					guard dataCount >= MemoryLayout<Bytes4>.size else {
					    return nil
					}
					dataCount -= MemoryLayout<Bytes4>.size
					let length = Int(Bytes4(RAW_staticbuff_seeking: &inputPtr).RAW_native())
					guard dataCount >= length else {
					    return nil
					}
					dataCount -= length
					guard let value = Self._decodeTagValue(NOSTR_id.self, inputPtr, length) else {
					    return nil
					}
					guard dataCount == 0 else {
					    return nil
					}
					self.value = value
					}
					public func RAW_encode(count: inout RAW.size_t) {
					count += MemoryLayout<NOSTR_tag_name>.size + MemoryLayout<Bytes4>.size
					value.RAW_encode(count: &count)
					}
					public func RAW_encode(dest: UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
					var dest = indexField.RAW_encode(dest: dest)

					var tagValueLength = 0;
					value.RAW_encode(count: &tagValueLength)
					let tagValueLengthBytes = Bytes4(RAW_native: UInt32(tagValueLength))
					dest = tagValueLengthBytes.RAW_encode(dest: dest)
					dest = value.RAW_encode(dest: dest)

					return dest
					}

					private static func _decodeTagValue<T: RAW_convertible>(_ type: T.Type, _ ptr: UnsafeRawPointer, _ len: RAW.size_t) -> T? {
						return T(RAW_decode: ptr, count: len)
					}
				}
				""",
				macroSpecs: testMacros
			) { failure in
				Issue.record(
					"\\(failure.message)",
					sourceLocation: .init(
						fileID: failure.location.fileID,
						filePath: failure.location.filePath,
						line: failure.location.line,
						column: failure.location.column
					)
				)
			}
		}

		@Test func memberMacroGeneratesIndexField() {
			assertMacroExpansion(
				"""
				@NostrTag(name: "e")
				struct ERef: Sendable, Hashable, Equatable, NOSTR_tag {
					var value: NOSTR_id
				}
				""",
				expandedSource: """
				struct ERef: Sendable, Hashable, Equatable, NOSTR_tag {
					var value: NOSTR_id

				    public var indexField = NOSTR_tag_name(string: "e")!
				}

				extension ERef: RAW_convertible {
					public init?(RAW_decode inputPtr: consuming UnsafeRawPointer, count: RAW.size_t) {
					var dataCount = count
					guard dataCount >= MemoryLayout<NOSTR_tag_name>.size else {
					    return nil
					}

					self.indexField = NOSTR_tag_name(RAW_staticbuff_seeking: &inputPtr)
					dataCount -= MemoryLayout<NOSTR_tag_name>.size
					guard indexField == NOSTR_tag_name(string: "e")! else {
					    return nil
					}

					guard dataCount >= MemoryLayout<Bytes4>.size else {
					    return nil
					}
					dataCount -= MemoryLayout<Bytes4>.size
					let length = Int(Bytes4(RAW_staticbuff_seeking: &inputPtr).RAW_native())
					guard dataCount >= length else {
					    return nil
					}
					dataCount -= length
					guard let value = Self._decodeTagValue(NOSTR_id.self, inputPtr, length) else {
					    return nil
					}
					guard dataCount == 0 else {
					    return nil
					}
					self.value = value
					}
					public func RAW_encode(count: inout RAW.size_t) {
					count += MemoryLayout<NOSTR_tag_name>.size + MemoryLayout<Bytes4>.size
					value.RAW_encode(count: &count)
					}
					public func RAW_encode(dest: UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
					var dest = indexField.RAW_encode(dest: dest)

					var tagValueLength = 0;
					value.RAW_encode(count: &tagValueLength)
					let tagValueLengthBytes = Bytes4(RAW_native: UInt32(tagValueLength))
					dest = tagValueLengthBytes.RAW_encode(dest: dest)
					dest = value.RAW_encode(dest: dest)

					return dest
					}

					private static func _decodeTagValue<T: RAW_convertible>(_ type: T.Type, _ ptr: UnsafeRawPointer, _ len: RAW.size_t) -> T? {
						return T(RAW_decode: ptr, count: len)
					}
				}
				""",
				macroSpecs: testMacros
			) { failure in
				Issue.record(
					"\\(failure.message)",
					sourceLocation: .init(
						fileID: failure.location.fileID,
						filePath: failure.location.filePath,
						line: failure.location.line,
						column: failure.location.column
					)
				)
			}
		}

		@Test func memberMacroDoesNotDuplicateExistingIndexField() {
			assertMacroExpansion(
				"""
				@NostrTag(name: "e")
				struct ERef: Sendable, Hashable, Equatable, NOSTR_tag {
					var indexField = NOSTR_tag_name(string: "e")!
					var value: NOSTR_id
				}
				""",
				expandedSource: """
				struct ERef: Sendable, Hashable, Equatable, NOSTR_tag {
					var indexField = NOSTR_tag_name(string: "e")!
					var value: NOSTR_id
				}

				extension ERef: RAW_convertible {
					public init?(RAW_decode inputPtr: consuming UnsafeRawPointer, count: RAW.size_t) {
					var dataCount = count
					guard dataCount >= MemoryLayout<NOSTR_tag_name>.size else {
					    return nil
					}

					self.indexField = NOSTR_tag_name(RAW_staticbuff_seeking: &inputPtr)
					dataCount -= MemoryLayout<NOSTR_tag_name>.size
					guard indexField == NOSTR_tag_name(string: "e")! else {
					    return nil
					}

					guard dataCount >= MemoryLayout<Bytes4>.size else {
					    return nil
					}
					dataCount -= MemoryLayout<Bytes4>.size
					let length = Int(Bytes4(RAW_staticbuff_seeking: &inputPtr).RAW_native())
					guard dataCount >= length else {
					    return nil
					}
					dataCount -= length
					guard let value = Self._decodeTagValue(NOSTR_id.self, inputPtr, length) else {
					    return nil
					}
					guard dataCount == 0 else {
					    return nil
					}
					self.value = value
					}
					public func RAW_encode(count: inout RAW.size_t) {
					count += MemoryLayout<NOSTR_tag_name>.size + MemoryLayout<Bytes4>.size
					value.RAW_encode(count: &count)
					}
					public func RAW_encode(dest: UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
					var dest = indexField.RAW_encode(dest: dest)

					var tagValueLength = 0;
					value.RAW_encode(count: &tagValueLength)
					let tagValueLengthBytes = Bytes4(RAW_native: UInt32(tagValueLength))
					dest = tagValueLengthBytes.RAW_encode(dest: dest)
					dest = value.RAW_encode(dest: dest)

					return dest
					}

					private static func _decodeTagValue<T: RAW_convertible>(_ type: T.Type, _ ptr: UnsafeRawPointer, _ len: RAW.size_t) -> T? {
						return T(RAW_decode: ptr, count: len)
					}
				}
				""",
				macroSpecs: testMacros
			) { failure in
				Issue.record(
					"\\(failure.message)",
					sourceLocation: .init(
						fileID: failure.location.fileID,
						filePath: failure.location.filePath,
						line: failure.location.line,
						column: failure.location.column
					)
				)
			}
		}
	}
}
