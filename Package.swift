// swift-tools-version:5.5

// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/03/2022.
//  All code (c) 2022 - present day, Elegant Chaos.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import PackageDescription

let package = Package(
    name: "BSA",
    
    platforms: [
        .macOS(.v12)
    ],
    
    products: [
        .library(
            name: "BSA",
            targets: ["BSA"]),
    ],
    
    dependencies: [
        .package(url: "https://github.com/elegantchaos/BinaryCoding.git", from: "1.0.0"),
        .package(url: "https://github.com/tsolomko/SWCompression.git", .upToNextMajor(from: "4.7.0")),
        .package(url: "https://github.com/elegantchaos/XCTestExtensions.git", from: "1.4.2")
    ],
    
    targets: [
        
        .target(
            name: "BSA",
            dependencies: [
                .product(name: "BinaryCoding", package: "BinaryCoding"),
                .product(name: "SWCompression", package: "SWCompression"),
            ]
        ),
        
        .testTarget(
            name: "BSATests",
            dependencies: ["BSA", "XCTestExtensions"],
            resources: [
                .process("Resources"),
            ]
        )
    ]
)
