// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 28/02/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BinaryCoding
import Compression
import Foundation
import SWCompression

public struct BSArchive {
    public let url: URL
    public let data: Data
    public let header: BSAHeader
    public let folders: [BSAFolder]
    
    public init(url: URL) throws {
        
        let data = try Data(contentsOf: url)
        let decoder = BSADecoder(data: data)
        let header = try decoder.decode(BSAHeader.self)
        
        decoder.header = header

        var folders: [BSAFolder] = []
        for _ in 0..<header.folderCount {
            folders.append(try decoder.decode(BSAFolder.self))
        }

        if header.flags.contains2(.includeFileNames) {
            for i in 0..<folders.count {
                for j in 0..<folders[i].files.count {
                    folders[i].files[j].name = try decoder.decode(String.self)
                }
            }
        }
        
        self.url = url
        self.header = header
        self.folders = folders
        self.data = data
    }
    
    public func extract(to url: URL) throws {
        let fm = FileManager.default
        
        for folder in folders {
            let folderPath = folder.name ?? "\(folder.nameHash)"
            var folderURL = url
            for component in folderPath.split(whereSeparator: { c in (c == "\\") || (c == "/") }) {
                folderURL = folderURL.appendingPathComponent(String(component))
            }
            try? fm.createDirectory(at: folderURL, withIntermediateDirectories: true)
            for file in folder.files {
                let fileName = file.name ?? "\(file.nameHash)"
                let fileURL = folderURL.appendingPathComponent(fileName)
                var offset = Int(file.offset)
                var size = Int(file.size)
                if header.flags.contains2(.embeddedFileNames) {
                    let nameLength = Int(data[offset])
                    offset += 1
                    size -= 1
                    let nameData = data[offset..<offset+nameLength]
                    let name = String(data: nameData, encoding: .utf8)
                    print("Embedded name \(name)")
                    offset += nameLength
                    size -= nameLength
                }
                if file.isCompressed {
                    let lengthBytes = data[offset..<offset+4].littleEndianBytes
                    let originalLength = try UInt32(littleEndianBytes: lengthBytes)
                    offset += 4 // skip the original size
                    size -= 4
                    let compressedData = Data(data[offset..<offset+size])
                    let decompressed = try LZ4.decompress(data: compressedData)
                    try decompressed.write(to: fileURL)
//                    let decompressed = try (compressedData as NSData).decompressed(using: .lz4)
//                    try decompressed.write(to: fileURL)
//                    try compressedData.lz4Decompress(originalSize: originalLength).write(to: fileURL)
//                    try decompress(compressedData, originalLength: originalLength, to: fileURL)
                } else {
                    let fileData = data[offset..<offset+size]
                    try fileData.write(to: fileURL)
                }
            }
        }
    }
    
    func decompress(_ data: Data, originalLength: UInt32, to url: URL) throws {
        let outputFile = try FileHandle(forWritingTo: url)
        let algorithm: Algorithm = header.version == 105 ? .lz4 : .zlib
        let outputFilter = try OutputFilter(.decompress, using: algorithm) { decompressed in
            if let data = decompressed {
                outputFile.write(data)
            }
        }
        
        try outputFilter.write(Data([UInt8(0x62), UInt8(0x76), UInt8(0x34), UInt8(0x31)]))
        try outputFilter.write(UInt32(originalLength).littleEndianBytes)
        try outputFilter.write(UInt32(data.count).littleEndianBytes)
        let bufferSize = 32_768
        var offset = 0
        var size = data.count
        while true {
            let chunkSize = min(size, bufferSize)
            let chunk = data[offset..<(offset+chunkSize)]
            try outputFilter.write(chunk)
            size -= chunkSize
            offset += chunkSize
            if size == 0 {
//                try outputFilter.write(Data([0x62, 0x76, 0x34, 0x24]))
                try outputFilter.finalize()
                break
            }
        }

        outputFile.closeFile()
    }
}

extension Data {

    func lz4Decompress(originalSize: UInt32) throws -> Data {
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(originalSize))
        let decompressed = try withUnsafeBytes { (sourceBuffer: UnsafeRawBufferPointer) throws -> Data in

            let size = compression_decode_buffer(
                destinationBuffer, Int(originalSize),
                sourceBuffer.baseAddress!, sourceBuffer.count,
                nil,    // scratch buffer automatically handled
                COMPRESSION_LZ4_RAW
            )

            if size == 0 {
                print("Error ")
                throw DecompressError.decompressionFailed
            }

            print("Original compressed size: \(sourceBuffer.count) | Decompressed size: \(size)")

            return Data(bytesNoCopy: destinationBuffer, count: size, deallocator: .free)
        }
        return decompressed
     }
}

enum DecompressError: Error {
    case decompressionFailed
}
