// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "nostr-kit-swift",
	platforms:[
		.macOS(.v15)
	],
    products: [
        .library(name: "nostr-kit-swift", targets: ["nostr-kit-swift"]),
    ],
	dependencies: [
		.package(url:"https://github.com/tannerdsilva/rawdog.git", revision: "1c4966c72102fc01b169cbc18ee5f0be10d802de"),
	],
    targets: [
        .target(
            name: "nostr-kit-swift",
			dependencies: [
				.product(name:"RAW", package:"rawdog"),
				.product(name:"RAW_dh25519", package:"rawdog"),
				.product(name:"RAW_ed25519", package:"rawdog"),
				.product(name:"RAW_sha256", package:"rawdog"),
				.product(name:"RAW_base64", package:"rawdog"),
			]
        ),
        .testTarget(
            name: "nostr-kit-swiftTests",
            dependencies: ["nostr-kit-swift"]
        ),
    ]
)
