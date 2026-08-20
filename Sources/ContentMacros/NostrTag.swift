import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum NostrTagError: CustomStringConvertible, Error {
	case onlyApplicableToStruct
	case doubleConformace(String)
	case missingMacroArgument(String)
	case nameTooLong(String)
	case emptyName

	/// The fixed width (in bytes) of the tag-name wire field. Kept in sync with
	/// `NOSTR_tag_name.maxNameBytes` in the library target.
	static let maxNameBytes = 8

	var description: String {
		switch self {
			case .onlyApplicableToStruct:
				return "@NostrTag can only be applied to structs"
			case .doubleConformace(let prot):
				return "@NostrTag double conforms to \(prot)"
			case .missingMacroArgument(let arg):
				return "@NostrTag missing argument: \(arg)"
			case .nameTooLong(let name):
				return "@NostrTag name \"\(name)\" is \(name.utf8.count) UTF-8 bytes; the tag-name wire field holds at most \(Self.maxNameBytes) bytes. Shorten the name."
			case .emptyName:
				return "@NostrTag name must not be empty; a tag requires a name of at least one character."
		}
	}
}

/// The macro adds the conformance and conformance functions
/// for `RAW_convertible` as an extension of the tag struct.
///
/// Parameters:
/// - `name`: The tag's index field. When provided, the raw decode initializer
///   checks that the tag's index field matches this name, and the macro generates
///   the `indexField` stored property (`NOSTR_tag_name(string: "<name>")!`).
/// - `valueType`: The tag's value type (the `tagValueType` associated type). When
///   provided, the macro generates the `value` stored property and an
///   `init(value:)` initializer for that type. The decode initializer always decodes
///   the value through a protocol-constrained generic helper (so it is always
///   treated as failable), regardless of whether the value type's concrete
///   `RAW_decode` initializer can return nil.
///
/// A struct may still declare its own `indexField` and/or `value`; if already
/// present, the macro leaves them alone.
public struct NostrTag: MemberMacro, ExtensionMacro {

	/// The label/value pair parsed from the macro attribute's arguments.
	struct Arguments {
		var name: String?
		var valueType: String?
	}

	static func parseArguments(of node: AttributeSyntax) -> Arguments {
		var arguments = Arguments()
		guard let labelledArgs = node.arguments?.as(LabeledExprListSyntax.self) else {
			return arguments
		}
		for arg in labelledArgs {
			guard let label = arg.label?.text else { continue }
			switch label {
				case "name":
					if let expr = arg.expression.as(StringLiteralExprSyntax.self),
					   let segment = expr.segments.first?.as(StringSegmentSyntax.self) {
						arguments.name = segment.content.text
					}
				case "valueType":
					arguments.valueType = Self.parseValueType(from: arg.expression)
				default:
					break
			}
		}
		return arguments
	}

	/// Extract the type name from a `valueType:` argument such as `EncodedString.self`.
	static func parseValueType(from expression: ExprSyntax) -> String? {
		// `EncodedString.self` → the base `EncodedString`.
		if let member = expression.as(MemberAccessExprSyntax.self), let base = member.base {
			return base.trimmedDescription
		}
		// Fallback: strip a trailing `.self`, or use the expression as-is.
		let desc = expression.trimmedDescription
		if desc.hasSuffix(".self") {
			return String(desc.dropLast(".self".count))
		}
		return desc.isEmpty ? nil : desc
	}

	/// Returns true if `name` is a representable tag name (non-empty and within
	/// the fixed 8-byte wire field). Used to decide whether to emit generated code.
	static func isValidName(_ name: String?) -> Bool {
		guard let name = name else { return true }
		if name.isEmpty { return false }
		return name.utf8.count <= NostrTagError.maxNameBytes
	}

	/// Validate a tag name and throw a compile error if it cannot be represented.
	/// Names must be non-empty and fit within the fixed 8-byte wire field.
	/// Only the MemberMacro expansion calls this, so an invalid name produces
	/// exactly one diagnostic.
	static func validateName(_ name: String?) throws {
		if name?.isEmpty == true {
			throw NostrTagError.emptyName
		}
		if let name = name, name.utf8.count > NostrTagError.maxNameBytes {
			throw NostrTagError.nameTooLong(name)
		}
	}

	/// Returns true if the declaration already declares a stored property named `name`.
	static func hasDeclaredMember(_ declaration: some DeclGroupSyntax, named name: String) -> Bool {
		for member in declaration.memberBlock.members {
			guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }
			for binding in varDecl.bindings {
				guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self) else { continue }
				if identifier.identifier.text == name {
					return true
				}
			}
		}
		return false
	}

	/// Find the declared `value` property's type, falling back to scanning the struct.
	/// Used by the extension macro when no `valueType:` parameter was provided.
	static func findDeclaredValueType(in declaration: some DeclGroupSyntax) -> String? {
		for member in declaration.memberBlock.members {
			guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }
			for binding in varDecl.bindings {
				guard let typeAnnotation = binding.typeAnnotation else { continue }
				guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self) else { continue }
				if identifier.identifier.text == "value" {
					return typeAnnotation.type.description
				}
			}
		}
		return nil
	}

	// MARK: - MemberMacro

	public static func expansion(
		of node: AttributeSyntax,
		providingMembersOf declaration: some DeclGroupSyntax,
		conformingTo protocols: [TypeSyntax],
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		let arguments = parseArguments(of: node)
		// Name validation happens here (the member expansion runs first and
		// produces exactly one diagnostic for an invalid name).
		try validateName(arguments.name)

		var members: [DeclSyntax] = []

		// Generate the indexField stored property from a fixed `name:`.
		if let name = arguments.name, !hasDeclaredMember(declaration, named: "indexField") {
			members.append(
				DeclSyntax(stringLiteral: "public var indexField = NOSTR_tag_name(string: \"\(name)\")!")
			)
		}

		// Generate the value stored property and its initializer from `valueType:`.
		if let valueType = arguments.valueType, !hasDeclaredMember(declaration, named: "value") {
			members.append(DeclSyntax(stringLiteral: "public var value: \(valueType)"))
			members.append(
				DeclSyntax(stringLiteral: "public init(value: \(valueType)) { self.value = value }")
			)
		}

		return members
	}

	// MARK: - ExtensionMacro

	public static func expansion(
		of node: SwiftSyntax.AttributeSyntax,
		attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
		providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
		conformingTo protocols: [SwiftSyntax.TypeSyntax],
		in context: some SwiftSyntaxMacros.MacroExpansionContext)
	throws -> [SwiftSyntax.ExtensionDeclSyntax] {
		
		let arguments = parseArguments(of: node)
		let nameValue = arguments.name
		// If the name is invalid, generate no extension at all. The MemberMacro
		// expansion has already emitted the single diagnostic for the invalid name.
		guard Self.isValidName(nameValue) else { return [] }
		
		guard declaration.inheritanceClause?.inheritedTypes.contains(where: {
			$0.type.trimmedDescription == "RAW_convertible"
		}) == false else  {
			throw NostrTagError.doubleConformace("RAW_convertible")
		}
		
		guard let structDecl = declaration.as(StructDeclSyntax.self) else {
			throw NostrTagError.onlyApplicableToStruct
		}
		
		// Resolve the value type. When `valueType:` is provided, use it directly —
		// the extension macro operates on the original source and cannot see the
		// `value` property generated by the member macro. Otherwise fall back to the
		// declared `value` property's type annotation.
		let valueType = arguments.valueType ?? Self.findDeclaredValueType(in: declaration)

		var rawDecodeInit = ""
		let rawEncodeCount =
			"""
			public func RAW_encode(count: inout RAW.size_t) {
				count += MemoryLayout<NOSTR_tag_name>.size + MemoryLayout<Bytes4>.size
				value.RAW_encode(count: &count)
			}
			"""
		let rawEncode =
			"""
			public func RAW_encode(dest: UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
				var dest = indexField.RAW_encode(dest: dest)

				var tagValueLength = 0; value.RAW_encode(count: &tagValueLength)
				let tagValueLengthBytes = Bytes4(RAW_native: UInt32(tagValueLength))
				dest = tagValueLengthBytes.RAW_encode(dest: dest)
				dest = value.RAW_encode(dest: dest)

				return dest
			}
			"""

		if let valueType = valueType {
			var nameCheckString: String {
				guard let name = nameValue else {
					return ""
				}
				// Safe to force-unwrap: the macro rejects names longer than
				// NOSTR_tag_name.maxNameBytes at compile time.
				return "guard indexField == NOSTR_tag_name(string: \"\(name)\")! else { return nil }"
			}

			rawDecodeInit =
				"""
				public init?(RAW_decode inputPtr:consuming UnsafeRawPointer, count: RAW.size_t) {
					var dataCount = count
					guard dataCount >= MemoryLayout<NOSTR_tag_name>.size else { return nil }

					self.indexField = NOSTR_tag_name(RAW_staticbuff_seeking: &inputPtr)
					dataCount -= MemoryLayout<NOSTR_tag_name>.size
					\(nameCheckString)

					guard dataCount >= MemoryLayout<Bytes4>.size else { return nil }
					dataCount -= MemoryLayout<Bytes4>.size
					let length = Int(Bytes4(RAW_staticbuff_seeking: &inputPtr).RAW_native())
					guard dataCount >= length else { return nil }
					dataCount -= length
					guard let value = Self._decodeTagValue(\(valueType).self, inputPtr, length) else { return nil }
					guard dataCount == 0 else { return nil }
					self.value = value
				}
				"""
		}
		
		return [
			try ExtensionDeclSyntax(
				"""
				extension \(raw: structDecl.name.text): RAW_convertible {
					\(raw: rawDecodeInit)
					\(raw: rawEncodeCount)
					\(raw: rawEncode)

					private static func _decodeTagValue<T: RAW_convertible>(_ type: T.Type, _ ptr: UnsafeRawPointer, _ len: RAW.size_t) -> T? {
						return T(RAW_decode: ptr, count: len)
					}
				}
				""")
		]
	}
}
