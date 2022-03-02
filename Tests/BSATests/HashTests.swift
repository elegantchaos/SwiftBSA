// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/03/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BSA
import XCTest
import XCTestExtensions


class HashTests: XCTestCase {
    func testPath() {
        XCTAssertEqual("interface\\exported\\widgets\\skyui".bsaHash, 179338418497549673)
    }
    
    func testFolder() {
        XCTAssertEqual("scripts".bsaHash, 3940292978845119603)
    }
    
    func testDDS() {
        XCTAssertEqual("glovesm_d.dds".bsaHash, 28521818684514276)
    }
    
    func testNIF() {
        XCTAssertEqual("body_overlay.nif".bsaHash, 6517425793139532153)
    }
    
    func testKF() {
        XCTAssertEqual("wibble.kf".bsaHash, 5415675663120493797)
    }

    func testWAV() {
        XCTAssertEqual("wibble.wav".bsaHash, 14648595538975812709)
    }
    
    func testTXT() {
        XCTAssertEqual("Another.txt".bsaHash, 14617328380702844274)
    }
}
