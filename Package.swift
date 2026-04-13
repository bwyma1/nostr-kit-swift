// swift-tools-version: 6.2
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "nostr-kit-swift",
	platforms:[
		.macOS(.v15)
	],
    products: [
        .library(name: "nostr-kit-swift", targets: ["nostr-kit-swift"]),
    ],
	dependencies: [
		.package(url:"https://github.com/apple/swift-syntax.git", "602.0.0"..<"603.0.0"),
		.package(url:"https://github.com/tannerdsilva/rawdog.git", revision: "1c4966c72102fc01b169cbc18ee5f0be10d802de"),
	],
    targets: [
		.macro(
			name: "ContentMacros",
			dependencies: [
				.product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
				.product(name: "SwiftCompilerPlugin", package: "swift-syntax")
			]
		),
        .target(
            name: "nostr-kit-swift",
			dependencies: [
				"ContentMacros",
				.product(name:"RAW", package:"rawdog"),
				.product(name:"RAW_dh25519", package:"rawdog"),
				.product(name:"RAW_ed25519", package:"rawdog"),
				.product(name:"RAW_sha256", package:"rawdog"),
				.product(name:"RAW_base64", package:"rawdog"),
			]
        ),
        .testTarget(
            name: "nostr-kit-swiftTests",
            dependencies: [
				"nostr-kit-swift",
				"ContentMacros",
				.product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
				.product(name: "SwiftSyntaxMacrosGenericTestSupport", package: "swift-syntax"),
			]
        ),
    ]
)
