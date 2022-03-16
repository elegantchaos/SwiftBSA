// swift-tools-version:5.5

// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/03/2022.
//  All code (c) 2022 - present day, Elegant Chaos.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import PackageDescription

let package = Package(
    name: "SwiftBSA",
    
    platforms: [
        .macOS(.v12)
    ],
    
    products: [
        .library(
            name: "SwiftBSA",
            targets: ["SwiftBSA"]),
    ],
    
    dependencies: [
        .package(url: "https://github.com/elegantchaos/BinaryCoding.git", from: "1.0.2"),
        .package(url: "https://github.com/elegantchaos/Logger.git", from: "1.7.3"),
        .package(url: "https://github.com/tsolomko/SWCompression.git", from: "4.7.0"),
        .package(url: "https://github.com/elegantchaos/XCTestExtensions.git", from: "1.4.2")
    ],
    
    targets: [
        
        .target(
            name: "SwiftBSA",
            dependencies: [
                .product(name: "BinaryCoding", package: "BinaryCoding"),
                .product(name: "Logger", package: "Logger"),
                .product(name: "SWCompression", package: "SWCompression"),
            ],
            exclude: [
                "hash.py"
            ]
        ),
        
        .testTarget(
            name: "SwiftBSATests",
            dependencies: ["SwiftBSA", "XCTestExtensions"],
            resources: [
                .process("Resources/Packed"),
                .process("Resources/Manifests"),
                .copy("Resources/Unpacked")
            ]
        )
    ]
)
