// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LeanCloud",
    platforms: [
        .iOS(.v11),
        .macOS(.v10_12),
        .tvOS(.v10),
        .watchOS(.v3)
    ],
    products: [
        .library(name: "LeanCloud", targets: ["LeanCloud"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.4.4")),
        .package(url: "https://github.com/apple/swift-protobuf.git", .upToNextMajor(from: "1.18.0")),
        .package(url: "https://github.com/groue/GRDB.swift.git", .upToNextMajor(from: "5.12.0"))
    ],
    targets: [
        .target(
            name: "LeanCloud",
            dependencies: [
                "Alamofire",
                "SwiftProtobuf",
                "GRDB"
            ],
            path: "Sources"
        )
    ],
    swiftLanguageVersions: [.v5]
)
