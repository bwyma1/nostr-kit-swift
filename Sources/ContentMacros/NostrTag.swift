import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum NostrTagError: CustomStringConvertible, Error {
	case onlyApplicableToStruct
	case doubleConformace(String)
	case missingMacroArgument(String)
	
	var description: String {
		switch self {
			case .onlyApplicableToStruct:
				return "@NostrTag can only be applied to structs"
			case .doubleConformace(let prot):
				return "@NostrTag double conforms to \(prot)"
			case .missingMacroArgument(let arg):
				return "@NostrTag missing argument: \(arg)"
		}
	}
}

/// The macro adds the conformance and conformance functions
/// for `RAW_convertible` as an extension of the tag struct
public struct NostrTag: ExtensionMacro {
	public static func expansion(
		of node: SwiftSyntax.AttributeSyntax,
		attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
		providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
		conformingTo protocols: [SwiftSyntax.TypeSyntax],
		in context: some SwiftSyntaxMacros.MacroExpansionContext)
	throws -> [SwiftSyntax.ExtensionDeclSyntax] {
		
		var nameValue: String?
		var safeDecodeValue: Bool = false
		
		if let arguments = node.arguments?.as(LabeledExprListSyntax.self) {
			for arg in arguments {
				guard let label = arg.label?.text else { continue }
				
				switch label {
					case "name":
						if let expr = arg.expression.as(StringLiteralExprSyntax.self),
						   let segment = expr.segments.first?.as(StringSegmentSyntax.self) {
							nameValue = segment.content.text
						}
						
					case "safeDecode":
						if let expr = arg.expression.as(BooleanLiteralExprSyntax.self) {
							safeDecodeValue = expr.literal.tokenKind == .keyword(.true)
						}
						
					default:
						break
				}
			}
		}
		
		guard declaration.inheritanceClause?.inheritedTypes.contains(where: {
			$0.type.trimmedDescription == "RAW_convertible"
		}) == false else  {
			throw NostrTagError.doubleConformace("RAW_convertible")
		}
		
		guard let structDecl = declaration.as(StructDeclSyntax.self) else {
			throw NostrTagError.onlyApplicableToStruct
		}
		
		let members = structDecl.memberBlock.members

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
		
		for memberBlockItem in members {
			guard let decl = memberBlockItem.decl.as(VariableDeclSyntax.self) else {
				continue
			}
							
			for pattern in decl.bindings {
				guard let typeAnnotation = pattern.typeAnnotation else {
					continue
				}
				
				guard let identifier = pattern.pattern.as(IdentifierPatternSyntax.self) else {
					continue
				}
				guard pattern.accessorBlock == nil else {
					continue
				}
				
				guard identifier.identifier.text == "value" else {
					continue
				}
				
				var decodeString: String {
					if safeDecodeValue {
						return "let value = \(typeAnnotation.type.description)(RAW_decode: inputPtr, count: length)"
					} else {
						return "guard let value = \(typeAnnotation.type.description)(RAW_decode: inputPtr, count: length) else { return nil }"
					}
				}
				var nameCheckString: String {
					guard let name = nameValue else {
						return ""
					}
					return "guard indexField == NOSTR_tag_name(string: \"\(name)\") else { return nil }"
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
						\(decodeString)
						guard dataCount == 0 else { return nil }
						self.value = value
					}
					"""
			}
		}
		
		return [
			try ExtensionDeclSyntax(
				"""
				extension \(raw: structDecl.name.text): RAW_convertible {
					\(raw: rawDecodeInit)
					\(raw: rawEncodeCount)
					\(raw: rawEncode)
				}
				""")
		]
	}
}
