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
    @discardableResult func testRoundtrip(_ name: String) throws -> Archive {
        let url = Bundle.module.url(forResource: name, withExtension: "", subdirectory: "Unpacked")!

        var packed = Archive(flags: [.includeFileNames, .includeDirectoryNames, .compressed])
        try packed.pack(url: url)

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
        
        return bsa
    }

    func testPacking() throws {
        hashChannel.enabled = true

        try testRoundtrip("Example")
//        let url = Bundle.module.url(forResource: "Example", withExtension: "", subdirectory: "Unpacked")!
//
//        var bsa = Archive(flags: [.includeFileNames, .includeDirectoryNames, .compressed])
//        try bsa.pack(url: url)
//
//        let roundtrip = Archive(bsa.data)
//        roundtrip.extract(to: <#T##URL#>)
//        let originalURL = Bundle.module.url(forResource: "Example", withExtension: "bsa")!
//        let original = try! Data(contentsOf: originalURL)
//
//        XCTAssertEqual(bsa.data, original)
    }
}
