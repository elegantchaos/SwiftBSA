// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 28/02/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BSA
import XCTest
import XCTestExtensions


class PackingTests: XCTestCase {
    
    /// Pack a folder to an archive, then check it.
    /// We can't do a binary comparison on the packed archive because the compression
    /// settings we're using may be slightly different, producing different results.
    ///
    /// So instead, we unpack the data again and check that it produces the same files.
    /// We check file/folder names, and file sizes, but not actually byte-by-byte contents.
    func testRoundtrip(_ name: String) throws {
        unpackingChannel.enabled = false

        let url = Bundle.module.url(forResource: name, withExtension: "", subdirectory: "Unpacked")!

        var packed = Archive(flags: [.includeFileNames, .includeDirectoryNames, .compressed])
        try packed.pack(url: url)

        let originalURL = Bundle.module.url(forResource: name, withExtension: "bsa")!
        let original = try! Data(contentsOf: originalURL)

        if original == packed.data {
            print("Archives match exactly.")
        } else {
            print("Archives don't match exactly - falling back to roundtrip comparison.")
            
            if original.count < packed.data.count {
                print("Didn't compress as well as the original")
            }
            
            let bsa = try Archive(data: packed.data)
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
        }
    }

    func testExample() throws {
        try testRoundtrip("Example")
    }
    
    func testMCM() throws {
        try testRoundtrip("MCMHelper")
    }

    func testCollegeEntry() throws {
        try testRoundtrip("CollegeEntry")
    }

    func testThugsNotAssassins() throws {
        try testRoundtrip("ThugsNotAssassins")
    }

}
