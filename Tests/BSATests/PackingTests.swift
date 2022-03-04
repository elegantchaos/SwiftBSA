// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 28/02/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BSA
import XCTest
import XCTestExtensions


class PackingTests: XCTestCase {
    func testPacking() throws {
        hashChannel.enabled = true

        let url = Bundle.module.url(forResource: "Example", withExtension: "", subdirectory: "Unpacked")!

        var bsa = Archive(flags: [.includeFileNames, .includeDirectoryNames, .compressed])
        try bsa.pack(url: url)
        
        let originalURL = Bundle.module.url(forResource: "Example", withExtension: "bsa")!
        let original = try! Data(contentsOf: originalURL)
        
        XCTAssertEqual(bsa.data, original)
    }
}
