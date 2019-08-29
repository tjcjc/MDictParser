//
//  MDictFileHandler.swift
//  MDictParser
//
//  Created by JasonTai on 2019/8/27.
//

import Foundation

struct MDictFileHandler {
    let index: Int
    let length: Int
    let fileHandler: FileHandle
    let fileName: String
    
    init?(fileName: String, index: Int = 0, length: Int? = nil) {
        self.fileName = fileName
        guard let path = Bundle.main.path(forResource: fileName, ofType: "mdx"),
        let handler = FileHandle(forReadingAtPath: path)  else {
            return nil
        }
        
        self.fileHandler = handler
        if let len = length {
            self.length = len
        } else if let attr = try? FileManager.default.attributesOfItem(atPath: path) {
            self.length = attr[FileAttributeKey.size] as! Int
        } else {
            return nil
        }
        self.index = index
    }
}

extension MDictFileHandler: MDictSourceProtocol {
    func readNum<T>(index: Int, isLittleEndian: Bool) -> T where T : FixedWidthInteger {
        let len = T.byteWidth
        let data = self.subData(index, length: len).rawData()
        // TODO: withUnsafeBytes is deprecated
        // waiting for another solution
        let tmpVal: T = data.withUnsafeBytes {  $0.pointee }
        if len > 1 {
            return isLittleEndian ? T(littleEndian: tmpVal) : T(bigEndian: tmpVal)
        } else {
            return tmpVal
        }
    }
    
    func subData(_ start: Int, length: Int) -> MDictFileHandler {
        return MDictFileHandler(fileName: self.fileName, index: self.index + start, length: length)!
    }
    
    var count: Int {
        return self.length
    }
    
    func rawData() -> Data {
        if #available(iOS 13.0, *) {
            do {
                try self.fileHandler.seek(toOffset: UInt64(self.index))
                return fileHandler.readData(ofLength: length)
            } catch {
                return Data()
            }
        } else {
            // Fallback on earlier versions
            fileHandler.seek(toFileOffset: UInt64(self.index))
            return fileHandler.readData(ofLength: length)
        }
    }
}

