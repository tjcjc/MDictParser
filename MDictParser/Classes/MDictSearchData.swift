//
//  MDictSearchData.swift
//  MDictParser
//
//  Created by JasonTai on 2019/8/27.
//

import MMKV

public final class MDictSearchData {
    let blockSize: [[Int]]
    let indexAndWords: [(Int, String)]
    let startIndex: Int
    let file: MDictFileHandler?
    let fileName: String

    init(startIndex: Int, fileName: String, blockSize: [[Int]], indexAndWords: [(Int, String)] = []) {
        self.startIndex = startIndex
        self.blockSize = blockSize
        self.indexAndWords = indexAndWords
        self.fileName = fileName
        
        if let handler = MDictFileHandler(fileName: fileName, index: self.startIndex) {
            self.file = handler
        } else {
            self.file = nil
        }
    }
    
    public func saveToCache() {
        let mmkv = MMKV.init(mmapID: "__MDictSearch\(fileName)")
        if let mmkv = mmkv {
            mmkv.clearAll()
            mmkv.set(Int64(self.startIndex), forKey: "__\(fileName)startIndex")
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(self.blockSize),
                let str = String(data: data, encoding: .utf8) {
                mmkv.set(str, forKey: "__\(fileName)blockSize")
            }
            let count = indexAndWords.count
            for i in 0 ..< (count) {
                let (offset, str) = indexAndWords[i]
                if (i < count - 1) {
                    mmkv.set(Int64(indexAndWords[i+1].0 - offset), forKey: "__\(str)length")
                } else {
                    mmkv.set(Int64(blockSize.reduce(0) {$0 + $1[1]} - offset), forKey: "__\(str)length")
                }
                mmkv.set(Int64(offset), forKey: "__\(str)offset")
            }
        }
    }
    
    public static func getDataFromCache(fileName: String) -> MDictSearchData? {
        let mmkv = MMKV.init(mmapID: "__MDictSearch\(fileName)")
        guard let cache = mmkv else {
            return nil
        }
        let startIndex: Int = Int(cache.int64(forKey: "__\(fileName)startIndex"))
        let decoder = JSONDecoder()
        if let jsonStr = cache.string(forKey: "__\(fileName)blockSize"),
            let data = jsonStr.data(using: .utf8),
            let blockData = try? decoder.decode([[Int]].self, from: data) {
            return MDictSearchData(startIndex: startIndex, fileName: fileName, blockSize: blockData)
        }
        return nil
    }
    
    public func searchWords(str: String) -> String? {
        let mmkv = MMKV.init(mmapID: "__MDictSearch\(fileName)")
        guard let cache = mmkv else {
            return nil
        }
        return self.searchWords(offset: Int(cache.int64(forKey: "__\(str)offset")),
                                length: Int(cache.int64(forKey: "__\(str)length")))
    }

    public func searchWords(offset: Int, length: Int) -> String {
        let offset = self.offsetOfWords(offset: offset)
        var data: Data?
        if let file = self.file {
            data = file.subData(offset.compressOffset, length: offset.blockSize).rawData()
        }
        if var compressData = data {
            let adler32: UInt32 = compressData.readNum(index: 4)
            let subData = compressData.subData(8, length: compressData.count - 8)
            if compressData.subData(length: 4).jtBytes == MDictData.compressSignal, let d = subData.unzip() {
                compressData = d
            } else {
                compressData = subData
            }
            assert(adler32 == compressData.adler32().checksum & 0xffffffff)

            let detailData = compressData.subData(offset.decompressOffset, length: length)
            return String(data: detailData, encoding: .utf8) ?? ""
        }
        return ""
    }

    func offsetOfWords(offset: Int) -> (compressOffset: Int, decompressOffset: Int, blockSize: Int) {
        var offset = offset
        var compressOffset = 0
        var blockSize = 0
        for size in self.blockSize {
            let cSize = size[0]
            let dSize = size[1]
            if offset >= dSize {
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
