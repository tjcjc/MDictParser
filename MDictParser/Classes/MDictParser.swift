//
//  MDictParser.swift
//  MDictParser
//
//  Created by JasonTai on 2019/8/26.
//

import Foundation
import JTUtils
import JT_CryptoSwift

public final class MDictParser {
    var dictData: MDictData
    var version: MDictVersion = .v1
    var encryptType: MDictEncryptType = .none
    var encoding: MDictEncoding = .utf8
    var wordsAndIndex: [(Int, String)] = []
    var numWords = 0
    var fileName: String = ""

    public init?(fileName: String) {
        guard let path = Bundle.main.path(forResource: fileName, ofType: "mdx") else {
            return nil
        }

        self.fileName = fileName
        let rawData = try! Data(contentsOf: URL(fileURLWithPath: path))
        self.dictData = MDictData(rawData: rawData)
    }
    
    public func getSearchData() -> MDictSearchData {
        self.version = self.dictData.version
        self.encoding = self.dictData.encoding
        self.parseKeys()
        let detailBlockSize = self.getDetailBlockSizeArray()
        return MDictSearchData(startIndex: self.dictData.index,
                                          fileName: fileName,
                                          blockSize: detailBlockSize,
                                          indexAndWords: self.wordsAndIndex)
    }

    /// get keys meta data size
    /// - Returns: [ blockCount, entriesCount, blockMetaDataSize, compressedBlockDataSize]
    func parseKeyDataSize() -> [Int] {
        var keySizeData = self.dictData.readSubData(length: version.keyHeaderLen, needCheck: version == .v2)
        var r: [Int] = []
        for i in 0..<(version == .v2 ? 5 : 4) {
            let number: UInt64 = keySizeData.readNum()
            if !(i == 2 && version == .v2) {
                r.append(Int(number))
            }
        }
        return r
    }

    func parseKeys() {
        let dataSize = self.parseKeyDataSize()
        let keyBlockSizeArray = self.getKeysBlockSizeArray(length: dataSize[2], numEntries: dataSize[1])
        assert(dataSize[0] == keyBlockSizeArray.count)
        wordsAndIndex = self.getIndexAndWords(length: dataSize[3], blockSize: keyBlockSizeArray)
        self.numWords = wordsAndIndex.count
    }


    func parseDetailBlock(blockSize: [(Int, Int)], wordsAndIndex: [(Int, String)]) -> [(String, String)] {
        var i = 0
        var offset = 0
        var dict: [(String, String)] = []
        var sizeCounter = 0
        let numRecord = wordsAndIndex.count
        for (compress, decompress) in blockSize {
            var decompressData = self.dictData.readSubData(length: compress)
            decompressData.decompress()
            assert(decompressData.data.count == decompress)
            sizeCounter += compress

            while i < numRecord {
                let startIndex = Int(wordsAndIndex[i].0)
                let keyText = wordsAndIndex[i].1
                // 如果当前要查的条目已经超过了块的index
                if startIndex - offset >= decompress {
                    break
                }
                var endIndex = 0
                if i < numRecord - 1 {
                    endIndex = wordsAndIndex[i+1].0
                } else {
                    endIndex = decompress + offset
                }
                let wordDetail = decompressData.readString(length: endIndex - startIndex)
                dict.append((keyText, wordDetail))
                i += 1
            }
            offset += decompress
        }
        return dict
    }

    func getIndexAndWords(length: Int, blockSize: [(Int, Int)]) -> [(Int, String)] {
        var blockData = self.dictData.readSubData(length: length)
        var r1: [(Int, String)] = []
        for (size, _) in blockSize {
            var subBlockData = blockData.readSubData(length: size)
            subBlockData.decompress()
            r1.append(contentsOf: subBlockData.fetchIndexAndWords())
        }
        return r1
    }

    func getDetailBlockSizeArray() -> [(Int, Int)] {
        let blockCount = self.dictData.readInt()
        let numRecord = self.dictData.readInt()
        assert(numRecord == wordsAndIndex.count)
        let metaSize = self.dictData.readInt()
        let recordSize = self.dictData.readInt()
        var r2: [(Int, Int)] = []
        var byteCount = 0
        for _ in 0 ..< blockCount {
            r2.append((self.dictData.readInt(), self.dictData.readInt()))
            byteCount += version.numBytes * 2
        }
        assert(byteCount == metaSize)
        return r2
    }

    func getKeysBlockSizeArray(length: Int, numEntries: Int) -> [(Int, Int)] {
        var metaData = self.dictData.readSubData(length: length)
        if version == .v2 {
            metaData.decompress(needDecrypt: true)
        }

        let count = metaData.data.count
        var index = 0
        var total = 0
        var r: [(Int, Int)] = []
        while index < count {
            total += metaData.readInt()
            metaData.forwardTextTail()
            r.append((metaData.readInt(), metaData.readInt()))
            index = metaData.index
        }
        assert(numEntries == total)
        return r
    }
}
