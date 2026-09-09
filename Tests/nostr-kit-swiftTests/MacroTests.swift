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
	public var variableA: Encoded.Bool
	public var variableB: Encoded.String?
}

@NostrContent
struct ComplexContent: Sendable, Equatable, Hashable {
	public var content: [BasicContent]?
	public var dictContent: [Encoded.String: [Encoded.UInt16?]]?
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
					public var content: Encoded.Bool
				}
				""",
				expandedSource: """
				struct SomeContent: Sendable, Equatable, Hashable {
					public var content: Encoded.Bool
				
				    public init(content: Encoded.Bool) {
				        self.content = content
				    }
				
				    public init(contentNative: Bool) {
				        self.content = Encoded.Bool(contentNative)
				    }
				}
				
				extension SomeContent: RAW_decodable, RAW_encodable {
					public init?(RAW_decode buffer: UnsafeRawBufferPointer) {
					    guard let baseAddress = buffer.baseAddress else {
					        return nil
					    }
					    var inputPtr = baseAddress
					    var dataCount = buffer.count
					    guard dataCount >= MemoryLayout<Encoded.Bool>.size else {
					        return nil
					    }
					    let content0 = Encoded.Bool(RAW_staticbuff_seeking: &inputPtr)
					    dataCount -= MemoryLayout<Encoded.Bool>.size
					    self.content = content0
					    guard dataCount == 0 else {
					        return nil
					    }
					}
					public func RAW_encode(count: inout Int) {
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
			var content = BasicContent(variableA: Encoded.Bool(true), variableB: Encoded.String("Hello World"))
			var contentLen: Int = 0; content.RAW_encode(count: &contentLen)
			let bufferA = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: contentLen)
			defer { bufferA.deallocate() }
			_ = content.RAW_encode(dest:bufferA.baseAddress!)
			var decodedContent = BasicContent(RAW_decode: UnsafeRawBufferPointer(start: bufferA.baseAddress!, count: contentLen))!
			#expect(content == decodedContent)
			
			content = BasicContent(variableA: Encoded.Bool(false), variableB: nil)
			contentLen = 0; content.RAW_encode(count: &contentLen)
			let bufferB = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: contentLen)
			defer { bufferB.deallocate() }
			_ = content.RAW_encode(dest:bufferB.baseAddress!)
			decodedContent = BasicContent(RAW_decode: UnsafeRawBufferPointer(start: bufferB.baseAddress!, count: contentLen))!
			#expect(content == decodedContent)
		}
		
		@Test func encodeDecodeComplexContent() throws {
			let dictContent: [Encoded.String: [Encoded.UInt16?]]? = [
				Encoded.String("first"): [Encoded.UInt16(1), Encoded.UInt16(2), nil],
				Encoded.String("second"): [nil, Encoded.UInt16(42)]
			]
			let content = ComplexContent(
				content: [
					BasicContent(variableA: Encoded.Bool(true), variableB: Encoded.String("Hello World")),
					BasicContent(variableA: Encoded.Bool(false), variableB: nil),
				],
				dictContent: dictContent
				)
			var contentLen: Int = 0; content.RAW_encode(count: &contentLen)
			let bufferA = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: contentLen)
			defer { bufferA.deallocate() }
			_ = content.RAW_encode(dest:bufferA.baseAddress!)
			let decodedContent = ComplexContent(RAW_decode: UnsafeRawBufferPointer(start: bufferA.baseAddress!, count: contentLen))!
			#expect(content == decodedContent)
		}
		
		@Test func truncatedContentDecodeRejectsOutOfBounds() throws {
			// Regression test for H1/H2: @NostrContent-generated decoders must not read
			// past the buffer on truncated input. BasicContent exercises the optional
			// presence-flag read (H2); ComplexContent additionally exercises the
			// dictionary-length read (H1). Each is truncated at every byte boundary —
			// the decoder must decode a complete prefix, return nil for a truncated
			// one, or reject — never crash or over-read.
			let basic = BasicContent(variableA: Encoded.Bool(true), variableB: Encoded.String("Hello World"))
			var basicLen: Int = 0; basic.RAW_encode(count: &basicLen)
			let basicBuffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: basicLen)
			defer { basicBuffer.deallocate() }
			_ = basic.RAW_encode(dest: basicBuffer.baseAddress!)
			for cut in 0..<basicLen {
				_ = BasicContent(RAW_decode: UnsafeRawBufferPointer(start: basicBuffer.baseAddress!, count: cut))
			}

			let dictContent: [Encoded.String: [Encoded.UInt16?]]? = [
				Encoded.String("first"): [Encoded.UInt16(1), Encoded.UInt16(2), nil]
			]
			let complex = ComplexContent(content: nil, dictContent: dictContent)
			var complexLen: Int = 0; complex.RAW_encode(count: &complexLen)
			let complexBuffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: complexLen)
			defer { complexBuffer.deallocate() }
			_ = complex.RAW_encode(dest: complexBuffer.baseAddress!)
			for cut in 0..<complexLen {
				_ = ComplexContent(RAW_decode: UnsafeRawBufferPointer(start: complexBuffer.baseAddress!, count: cut))
			}
		}
		
		@Test func encodeDecodeTag() throws {
			let nostrId = try generateSecureRandomBytes(count: 32).withUnsafeBytes { NOSTR_id(RAW_decode: UnsafeRawBufferPointer($0))! }
			let content = try DTag(value: nostrId)
			var contentLen: Int = 0; content.RAW_encode(count: &contentLen)
			let bufferA = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: contentLen)
			defer { bufferA.deallocate() }
			_ = content.RAW_encode(dest:bufferA.baseAddress!)
			let decodedContent = DTag(RAW_decode: UnsafeRawBufferPointer(start: bufferA.baseAddress!, count: contentLen))!
			#expect(content == decodedContent)
		}

		@Test func tagNameEmptyIsACompileError() {
			assertMacroExpansion(
				"""
				@NostrTag(name: "")
				struct EmptyTag: Sendable, Hashable, Equatable, NOSTR_tag {
					var indexField: NOSTR_tag_name
					var value: Encoded.String
				}
				""",
				expandedSource: """
				struct EmptyTag: Sendable, Hashable, Equatable, NOSTR_tag {
					var indexField: NOSTR_tag_name
					var value: Encoded.String
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

		@Test func tagNameOverEightBytesIsACompileError() {
			assertMacroExpansion(
				"""
				@NostrTag(name: "expiration")
				struct ExpTag: Sendable, Hashable, Equatable, NOSTR_tag {
					var indexField: NOSTR_tag_name
					var value: Encoded.String
				}
				""",
				expandedSource: """
				struct ExpTag: Sendable, Hashable, Equatable, NOSTR_tag {
					var indexField: NOSTR_tag_name
					var value: Encoded.String
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
				
				extension DTag: RAW_decodable, RAW_encodable {
					public init?(RAW_decode buffer: UnsafeRawBufferPointer) {
					guard let baseAddress = buffer.baseAddress else {
					    return nil
					}
					var inputPtr = baseAddress
					var dataCount = buffer.count
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
					public func RAW_encode(count: inout Int) {
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
					@discardableResult
					public func RAW_encode(_: UnsafeMutableRawPointer.Type, destination: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
					return UnsafeMutableRawPointer(RAW_encode(dest: destination.assumingMemoryBound(to: UInt8.self)))
					}
				
					private static func _decodeTagValue<T: RAW_decodable & RAW_encodable>(_ type: T.Type, _ ptr: UnsafeRawPointer, _ len: Int) -> T? {
						return T(RAW_decode: UnsafeRawBufferPointer(start: ptr, count: len))
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
				
				extension ERef: RAW_decodable, RAW_encodable {
					public init?(RAW_decode buffer: UnsafeRawBufferPointer) {
					guard let baseAddress = buffer.baseAddress else {
					    return nil
					}
					var inputPtr = baseAddress
					var dataCount = buffer.count
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
					public func RAW_encode(count: inout Int) {
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
					@discardableResult
					public func RAW_encode(_: UnsafeMutableRawPointer.Type, destination: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
					return UnsafeMutableRawPointer(RAW_encode(dest: destination.assumingMemoryBound(to: UInt8.self)))
					}
				
					private static func _decodeTagValue<T: RAW_decodable & RAW_encodable>(_ type: T.Type, _ ptr: UnsafeRawPointer, _ len: Int) -> T? {
						return T(RAW_decode: UnsafeRawBufferPointer(start: ptr, count: len))
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
				
				extension ERef: RAW_decodable, RAW_encodable {
					public init?(RAW_decode buffer: UnsafeRawBufferPointer) {
					guard let baseAddress = buffer.baseAddress else {
					    return nil
					}
					var inputPtr = baseAddress
					var dataCount = buffer.count
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
					public func RAW_encode(count: inout Int) {
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
					@discardableResult
					public func RAW_encode(_: UnsafeMutableRawPointer.Type, destination: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
					return UnsafeMutableRawPointer(RAW_encode(dest: destination.assumingMemoryBound(to: UInt8.self)))
					}
				
					private static func _decodeTagValue<T: RAW_decodable & RAW_encodable>(_ type: T.Type, _ ptr: UnsafeRawPointer, _ len: Int) -> T? {
						return T(RAW_decode: UnsafeRawBufferPointer(start: ptr, count: len))
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
	}
}
