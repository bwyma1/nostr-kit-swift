import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum NostrContentError: CustomStringConvertible, Error {
	case onlyApplicableToStruct
	case doubleConformace(String)
	
	var description: String {
		switch self {
			case .onlyApplicableToStruct:
				return "@NostrContent can only be applied to structs"
			case .doubleConformace(let prot):
				return "@NostrContent double conforms to \(prot)"
		}
	}
}

fileprivate let nostrContentTypes = ["EncodedBool", "EncodedUInt16", "EncodedUInt32", "EncodedUInt64", "EncodedUInt128", "EncodedInt16", "EncodedInt32", "EncodedUInt64", "EncodedInt128", "EncodedFloat", "EncodedString"]

fileprivate func rawDecodeIdentifierSyntax(identifier:String, type: String, layer: Int) -> String {
	if type == "EncodedString" {
		return
			"""
			guard dataCount >= MemoryLayout<Bytes4>.size else { return nil }
			let \(identifier)Length = Int(Bytes4(RAW_staticbuff_seeking: &inputPtr).RAW_native())
			dataCount -= MemoryLayout<Bytes4>.size
			guard dataCount >= \(identifier)Length else { return nil }
			let \(identifier)\(layer) = \(type)(RAW_decode: inputPtr, count: \(identifier)Length)
			inputPtr = inputPtr.advanced(by: \(identifier)Length)
			dataCount -= \(identifier)Length\n
			"""
	} else if nostrContentTypes.contains(type) {
		return
			"""
			guard dataCount >= MemoryLayout<\(type)>.size else { return nil }
			let \(identifier)\(layer) = \(type)(RAW_staticbuff_seeking: &inputPtr)
			dataCount -= MemoryLayout<\(type)>.size\n
			"""
	} else {
		return
			"""
			guard dataCount >= MemoryLayout<Bytes4>.size else { return nil }
			let \(identifier)Length = Int(Bytes4(RAW_staticbuff_seeking: &inputPtr).RAW_native())
			dataCount -= MemoryLayout<Bytes4>.size
			guard dataCount >= \(identifier)Length else { return nil }
			guard let \(identifier)\(layer) = \(type)(RAW_decode: inputPtr, count: \(identifier)Length) else { return nil }
			inputPtr = inputPtr.advanced(by: \(identifier)Length)
			dataCount -= \(identifier)Length\n
			"""
	}
}

fileprivate func rawEncodeCountIdentifierSyntax(identifier:String, type: String, layer: Int) -> String {
	if type == "EncodedString" {
		return
			"""
			count += MemoryLayout<Bytes4>.size
			\(identifier).RAW_encode(count: &count)
			"""
	} else if nostrContentTypes.contains(type) {
		return
			"""
			\(identifier).RAW_encode(count: &count)
			"""
	} else {
		return
			"""
			count += MemoryLayout<Bytes4>.size
			\(identifier).RAW_encode(count: &count)
			"""
	}
}

fileprivate func rawEncodeIdentifierSyntax(identifier:String, type: String, layer: Int) -> String {
	if type == "EncodedString" {
		return
			"""
			var \(identifier)Length = 0; \(identifier).RAW_encode(count: &\(identifier)Length)
			let \(identifier)LengthBytes = Bytes4(RAW_native: UInt32(\(identifier)Length))
			dest = \(identifier)LengthBytes.RAW_encode(dest: dest)
			dest = \(identifier).RAW_encode(dest: dest)
			"""
	} else if nostrContentTypes.contains(type) {
		return
			"""
			dest = \(identifier).RAW_encode(dest: dest)
			"""
	} else {
		return
			"""
			var \(identifier)Length = 0; \(identifier).RAW_encode(count: &\(identifier)Length)
			let \(identifier)LengthBytes = Bytes4(RAW_native: UInt32(\(identifier)Length))
			dest = \(identifier)LengthBytes.RAW_encode(dest: dest)
			dest = \(identifier).RAW_encode(dest: dest)
			"""
	}
}


fileprivate func resolveDecodeTypeAnnotation(type: TypeSyntax, identifier: String, layer: Int) -> String {
	var result: String = ""
	if layer == 0 {
		if type.as(DictionaryTypeSyntax.self) != nil {
			result += "self.\(identifier) = [:]"
		}
		if type.as(ArrayTypeSyntax.self) != nil {
			result += "self.\(identifier) = []"
		}
	}
	
	if let dictType = type.as(DictionaryTypeSyntax.self) {
		result +=
			"""
			var \(identifier)\(layer): \(dictType.description) = [:]
			let \(identifier)\(layer)DictLength = Int(Bytes4(RAW_staticbuff_seeking: &inputPtr).RAW_native())
			dataCount -= MemoryLayout<Bytes4>.size
			for _ in 0..<\(identifier)\(layer)DictLength {\n
			"""
		result += resolveDecodeTypeAnnotation(type: dictType.key, identifier: identifier + "Key", layer: layer + 1)
		result += resolveDecodeTypeAnnotation(type: dictType.value, identifier: identifier + "Value", layer: layer + 1)
		result +=
			"""
			\(identifier)\(layer)[\(identifier + "Key")\(layer + 1)] = \(identifier + "Value")\(layer + 1)
			}\n
			"""
	} else if let typeArray = type.as(ArrayTypeSyntax.self) {
		result +=
			"""
			var \(identifier)\(layer): \(typeArray.description) = []
			guard dataCount >= MemoryLayout<Bytes4>.size else { return nil }
			let \(identifier)\(layer)ArrayLength = Int(Bytes4(RAW_staticbuff_seeking: &inputPtr).RAW_native())
			dataCount -= MemoryLayout<Bytes4>.size
			for _ in 0..<\(identifier)\(layer)ArrayLength {\n
			"""
		result += resolveDecodeTypeAnnotation(type: typeArray.element, identifier: identifier, layer: layer + 1)
		result +=
			"""
			\(identifier)\(layer).append(\(identifier)\(layer + 1))
			}\n
			"""
	} else if let optionalType = type.as(OptionalTypeSyntax.self) {
		result +=
			"""
			var \(identifier)\(layer): \(optionalType.description)
			let \(identifier)Exists = EncodedBool(RAW_staticbuff_seeking: &inputPtr)
			dataCount -= MemoryLayout<EncodedBool>.size
			if \(identifier)Exists.bool {\n
			"""
		result += resolveDecodeTypeAnnotation(type: optionalType.wrappedType, identifier: identifier, layer: layer + 1)
		result +=
			"""
			\(identifier)\(layer) = \(identifier)\(layer + 1)
			} else {
				\(identifier)\(layer) = nil
			}\n
			"""
	} else if let type = type.as(IdentifierTypeSyntax.self) {
		result += rawDecodeIdentifierSyntax(identifier: identifier, type: type.name.text, layer: layer)
	}
	
	if layer == 0 {
		result += "self.\(identifier) = \(identifier)0\n"
	}
	return result
}

fileprivate func resolveEncodeCountTypeAnnotation(type: TypeSyntax, identifier: String, layer: Int) -> String {
	var result: String = ""
	
	if let dictType = type.as(DictionaryTypeSyntax.self) {
		result +=
			"""
			count += MemoryLayout<Bytes4>.size
			for (\(identifier)Key\(layer), \(identifier)Val\(layer)) in \(identifier) {\n
			"""
		result += resolveEncodeCountTypeAnnotation(type: dictType.key, identifier: "\(identifier)Key\(layer)", layer: layer + 1)
		result += resolveEncodeCountTypeAnnotation(type: dictType.value, identifier: "\(identifier)Val\(layer)", layer: layer + 1)
		result += "}\n"
	} else if let typeArray = type.as(ArrayTypeSyntax.self) {
		result +=
			"""
			count += MemoryLayout<Bytes4>.size
			for \(identifier)\(layer) in \(identifier) {\n
			"""
		result += resolveEncodeCountTypeAnnotation(type: typeArray.element, identifier: "\(identifier)\(layer)", layer: layer + 1)
		result += "}\n"
	} else if let optionalType = type.as(OptionalTypeSyntax.self) {
		result +=
			"""
			count += MemoryLayout<EncodedBool>.size
			if let \(identifier) = \(identifier){\n
			"""
		result += resolveEncodeCountTypeAnnotation(type: optionalType.wrappedType, identifier: identifier, layer: layer)
		result += "}\n"
	} else if let type = type.as(IdentifierTypeSyntax.self) {
		result += rawEncodeCountIdentifierSyntax(identifier: identifier, type: type.name.text, layer: layer)
	}	
	return result
}

fileprivate func resolveEncodeTypeAnnotation(type: TypeSyntax, identifier: String, layer: Int) -> String {
	var result: String = ""
	
	if let dictType = type.as(DictionaryTypeSyntax.self) {
		result +=
			"""
			let \(identifier)Count = Bytes4(RAW_native: UInt32(\(identifier).count))
			dest = \(identifier)Count.RAW_encode(dest: dest)
			for (\(identifier)Key\(layer), \(identifier)Val\(layer)) in \(identifier) {\n
			"""
		result += resolveEncodeTypeAnnotation(type: dictType.key, identifier: "\(identifier)Key\(layer)", layer: layer + 1)
		result += resolveEncodeTypeAnnotation(type: dictType.value, identifier: "\(identifier)Val\(layer)", layer: layer + 1)
		result += "}\n"
	} else if let typeArray = type.as(ArrayTypeSyntax.self) {
		result +=
			"""
			let \(identifier)Count = Bytes4(RAW_native: UInt32(\(identifier).count))
			dest = \(identifier)Count.RAW_encode(dest: dest)
			for \(identifier)\(layer) in \(identifier) {\n
			"""
		result += resolveEncodeTypeAnnotation(type: typeArray.element, identifier: "\(identifier)\(layer)", layer: layer + 1)
		result += "}\n"
	} else if let optionalType = type.as(OptionalTypeSyntax.self) {
		result +=
			"""
			if let \(identifier) = \(identifier){
				dest = EncodedBool(true).RAW_encode(dest: dest)\n
			"""
		result += resolveEncodeTypeAnnotation(type: optionalType.wrappedType, identifier: identifier, layer: layer)
		result +=
			"""
			} else {
				dest = EncodedBool(false).RAW_encode(dest: dest)
			}\n
			"""
	} else if let type = type.as(IdentifierTypeSyntax.self) {
		result += rawEncodeIdentifierSyntax(identifier: identifier, type: type.name.text, layer: layer)
	}
	return result
}


public struct NostrContent: ExtensionMacro {
	public static func expansion(
		of node: SwiftSyntax.AttributeSyntax,
		attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
		providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
		conformingTo protocols: [SwiftSyntax.TypeSyntax],
		in context: some SwiftSyntaxMacros.MacroExpansionContext)
	throws -> [SwiftSyntax.ExtensionDeclSyntax] {
		guard declaration.inheritanceClause?.inheritedTypes.contains(where: {
			$0.type.trimmedDescription == "RAW_convertible"
		}) == false else  {
			throw NostrContentError.doubleConformace("RAW_convertible")
		}
		
		guard let structDecl = declaration.as(StructDeclSyntax.self) else {
			throw NostrContentError.onlyApplicableToStruct
		}
		
		let members = structDecl.memberBlock.members

		var rawDecodeInit =
			"""
			public init?(RAW_decode inputPtr:consuming UnsafeRawPointer, count: RAW.size_t) {
			var inputPtr = inputPtr
			var dataCount = count\n
			"""
		var rawEncodeCount = "public func RAW_encode(count: inout RAW.size_t) {\n"
		var rawEncode =
			"""
			public func RAW_encode(dest: UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
			var dest = dest\n
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
				
				rawDecodeInit += resolveDecodeTypeAnnotation(type: typeAnnotation.type, identifier: identifier.identifier.text, layer: 0)
				rawEncodeCount += resolveEncodeCountTypeAnnotation(type: typeAnnotation.type, identifier: identifier.identifier.text, layer: 0)
				rawEncode += resolveEncodeTypeAnnotation(type: typeAnnotation.type, identifier: identifier.identifier.text, layer: 0)
			}
		}
		rawDecodeInit +=
			"""
			guard dataCount == 0 else { return nil }
			}
			"""
		rawEncodeCount += "}"
		rawEncode +=
			"""
			return dest
			}
			"""
		
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

extension NostrContent: MemberMacro {
	public static func expansion(
		of node: AttributeSyntax,
		providingMembersOf declaration: some DeclGroupSyntax,
		conformingTo protocols: [TypeSyntax],
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		
		guard let structDecl = declaration.as(StructDeclSyntax.self) else {
			throw NostrContentError.onlyApplicableToStruct
		}
		
//		let x = structDecl.
		
		let members = structDecl.memberBlock.members
		
		// Create basic initializer
		var initializerDecl = "public init("
		var initializerBlock = ""
		for memberBlockItem in members {
			guard let variableDecl = memberBlockItem.decl.as(VariableDeclSyntax.self) else {
				continue
			}
							
			for pattern in variableDecl.bindings {
				guard let typeAnnotation = pattern.typeAnnotation else {
					continue
				}
				
				guard let identifier = pattern.pattern.as(IdentifierPatternSyntax.self) else {
					continue
				}
				guard pattern.accessorBlock == nil else {
					continue
				}
				
				initializerDecl += "\(identifier.identifier.text):\(typeAnnotation.type.description),"
				initializerBlock += "self.\(identifier.identifier.text) = \(identifier.identifier.text)\n"
								
			}
		}
		initializerDecl.removeLast()
		let initializer = "\(initializerDecl)) {\n\(initializerBlock)}"
		
		// Create specialized initializer
		var foundationInitializerDecl = "public init("
		var foundationInitializerBlock = ""
		for memberBlockItem in members {
			guard let variableDecl = memberBlockItem.decl.as(VariableDeclSyntax.self) else {
				continue
			}
							
			for pattern in variableDecl.bindings {
				guard let typeAnnotation = pattern.typeAnnotation else {
					continue
				}
				
				guard let identifier = pattern.pattern.as(IdentifierPatternSyntax.self) else {
					continue
				}
				guard pattern.accessorBlock == nil else {
					continue
				}
				
				let trimmedType = typeAnnotation.type.description.replacingOccurrences(of: "?", with: "")
				let parameterName = identifier.identifier.text + "Native"
				if nostrContentTypes.contains(trimmedType) {
					foundationInitializerDecl += "\(parameterName):\(typeAnnotation.type.description.replacingOccurrences(of: "Encoded", with: "")),"
					
					let typeValue: String
					if trimmedType == "EncodedString" || trimmedType == "EncodedBool" {
						typeValue = "(\(parameterName))"
					} else {
						typeValue = "(RAW_native: \(parameterName))"
					}
					
					if let optionalType = typeAnnotation.type.as(OptionalTypeSyntax.self) {
						
						foundationInitializerBlock += """
							if let \(parameterName) = \(parameterName) {
								self.\(identifier.identifier.text) = \(optionalType.wrappedType.description)\(typeValue)
							} else {
								self.\(identifier.identifier.text) = nil
							}
							"""
					} else {
						foundationInitializerBlock += "self.\(identifier.identifier.text) = \(typeAnnotation.type.description)\(typeValue)\n"
					}
				} else {
					foundationInitializerDecl += "\(identifier.identifier.text):\(typeAnnotation.type.description),"
					foundationInitializerBlock += "self.\(identifier.identifier.text) = \(identifier.identifier.text)\n"
				}
								
			}
		}
		foundationInitializerDecl.removeLast()
		let foundationInitializer = "\(foundationInitializerDecl)) {\n\(foundationInitializerBlock)}"

		guard initializer != foundationInitializer else {
			return [DeclSyntax(stringLiteral: initializer)]
		}
		return [
			DeclSyntax(stringLiteral: initializer),
			DeclSyntax(stringLiteral: foundationInitializer)
		]
	}
}

@main
struct ContentMacrosPlugin: CompilerPlugin {
	let providingMacros: [Macro.Type] = [
		NostrContent.self
	]
}
