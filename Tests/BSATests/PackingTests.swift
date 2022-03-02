// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 28/02/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BSA
import XCTest
import XCTestExtensions


class PackingTests: XCTestCase {
    func testPacking() throws {
        let url = Bundle.module.url(forResource: "Example", withExtension: "", subdirectory: "Unpacked")!

        var bsa = Archive()
        try bsa.pack(url: url)
    }
}
