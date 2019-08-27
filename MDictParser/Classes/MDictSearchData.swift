//
//  MDictSearchData.swift
//  MDictParser
//
//  Created by JasonTai on 2019/8/27.
//

import MMKV

public final class MDictSearchData {
    let fileName: String
    let blockSize: [(Int, Int)]
    let indexAndWords: [(Int, String)]
    let startIndex: Int
    let file: FileHandle?

    init(startIndex: Int, fileName: String, blockSize: [(Int, Int)], indexAndWords: [(Int, String)]) {
        self.startIndex = startIndex
        self.fileName = fileName
        self.blockSize = blockSize
        self.indexAndWords = indexAndWords
        let mmkv = MMKV.default()
        for (index, str) in indexAndWords {
            mmkv.set(Int64(index), forKey: str)
        }
        if let path = Bundle.main.path(forResource: fileName, ofType: "mdx") {
            self.file = FileHandle(forReadingAtPath: path)
        } else {
            self.file = nil
        }
    }

    public func searchWords(index: Int) {
        print(self.indexAndWords.count)
        assert(index < self.indexAndWords.count)
        let offset = self.offsetOfWords(index: index)
        var data: Data?
        if let file = self.file {
            if #available(iOS 13.0, *) {
                do {
                    try file.seek(toOffset: UInt64(self.startIndex + offset.compressOffset))
                    data = file.readData(ofLength: offset.blockSize)
                } catch {
                    data = nil
                }
            } else {
                // Fallback on earlier versions
                file.seek(toFileOffset: UInt64(self.startIndex + offset.compressOffset))
                data = file.readData(ofLength: offset.blockSize)
            }
        }
        if var compressData = data {
            let adler32: UInt32 = compressData.readNum(index: 4)
            let subData = compressData.subData(8, length: compressData.count - 8)
            if compressData.subData(length: 4).bytes == MDictData.compressSignal, let d = subData.unzip() {
                compressData = d
            } else {
                compressData = subData
            }
            assert(adler32 == compressData.adler32().checksum & 0xffffffff)

            let length: Int
            if index == self.indexAndWords.count - 1 {
                length = compressData.count - offset.decompressOffset
            } else {
                length = self.indexAndWords[index + 1].0 - self.indexAndWords[index].0
            }
            let detailData = compressData.subData(offset.decompressOffset, length: length)
            print(String(data: detailData, encoding: .utf8) ?? "", self.indexAndWords[index].1)
        }
    }

    func offsetOfWords(index: Int) -> (compressOffset: Int, decompressOffset: Int, blockSize: Int) {
        var offset = self.indexAndWords[index].0
        var compressOffset = 0
        var blockSize = 0
        for (cSize, dSize) in self.blockSize {
            if offset > dSize {
                offset -= dSize
                compressOffset += cSize
            } else {
                blockSize = cSize
                break
            }
        }
        return (compressOffset, offset, blockSize)
    }
}
