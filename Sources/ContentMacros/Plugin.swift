import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct ContentMacrosPlugin: CompilerPlugin {
	let providingMacros: [Macro.Type] = [
		NostrContent.self,
		NostrTag.self
	]
}
