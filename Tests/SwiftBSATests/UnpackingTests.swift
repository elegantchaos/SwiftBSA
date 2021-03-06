// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 28/02/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftBSA
import XCTest
import XCTestExtensions


class UnpackingTests: XCTestCase {
    @discardableResult func testExtraction(_ name: String) throws -> Archive {
        let url = Bundle.module.url(forResource: name, withExtension: "bsa")!
        let bsa = try Archive(url: url)
        let output = outputDirectory().appendingPathComponent(name)
        try bsa.extract(to: output)

        XCTAssertEqual(bsa.id, "BSA\0")
        XCTAssertEqual(bsa.version, 105)

        var paths: [String] = []
        let enumerator = FileManager.default.enumerator(at: output, includingPropertiesForKeys: nil, options: [.producesRelativePathURLs])!
        for case let url as URL in enumerator {
            let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize
            let sizeString = size.map { ", \($0)" } ?? ""
            paths.append("\(url.relativePath)\(sizeString)")
        }
        let manifest = paths.joined(separator: "\n")

        if let manifestURL = Bundle.module.url(forResource: name, withExtension: "txt") {
            let loadedManifest = String(data: try Data(contentsOf: manifestURL), encoding: .utf8)!
            XCTAssertEqual(manifest, loadedManifest)
        } else {
            print(manifest)
        }
        
        return bsa
    }
    
    func testExtractMCMHelper() throws {
        let archive = try testExtraction("MCMHelper")
        XCTAssertEqual(archive.folderCount, 2)
        XCTAssertEqual(archive.content, [.shaders])
        XCTAssertEqual(archive.flags, [.includeFileNames, .includeDirectoryNames, .compressed])
    }

    func testThugsNotAssassins() throws {
        let archive = try testExtraction("ThugsNotAssassins")
        XCTAssertEqual(archive.folderCount, 2)
        XCTAssertEqual(archive.content, [.sounds])
        XCTAssertEqual(archive.flags, [.includeFileNames, .includeDirectoryNames, .retainFileNames])
    }

    func testCollegeEntry() throws {
        let archive = try testExtraction("CollegeEntry")
        XCTAssertEqual(archive.folderCount, 4)
        XCTAssertEqual(archive.content, [.sounds])
        XCTAssertEqual(archive.flags, [.includeFileNames, .includeDirectoryNames, .retainFileNames])
    }

//    func testExtractRaceMenu() throws {
//        try testExtraction("RaceMenu")
//    }
}
