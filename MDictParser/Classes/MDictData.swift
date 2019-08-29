//
//  MDictData.swift
//  MDictParser
//
//  Created by JasonTai on 2019/8/27.
//

struct MDictData {
    var data: MDictSourceProtocol
    var index: Data.Index
    var version: MDictVersion = .v2
    var encoding: MDictEncoding = .utf8
    static let compressSignal: [UInt8] = [2, 0, 0, 0]
    var delimiter: [UInt8] = [0]

    init(data: MDictSourceProtocol, version: MDictVersion, encoding: MDictEncoding) {
        self.data = data
        self.index = 0
        self.version = version
        self.encoding = encoding
        self.delimiter = encoding.delimiter
    }

    init(rawData: MDictSourceProtocol) {
        self.data = rawData
        self.index = 0
        self.parseHeader()
    }

    init?(fileName: String) {
        guard let path = Bundle.main.path(forResource: fileName, ofType: "mdx") else {
            return nil
        }

        let rawData = try! Data(contentsOf: URL(fileURLWithPath: path))
        self.init(rawData: rawData)
    }

    mutating func forward(step: Int) {
        self.index += step
    }

    mutating func parseHeader() {
        let length: UInt32 = self.readNum()
        let headerData = self.readSubRawData(length: Int(length))
        checkAlder32(data: headerData, isLittle: true)
        let header = self.scanHeader(headerData: headerData)
        if let version = header["generatedbyengineversion"], let v = Double(version) {
            self.version = MDictVersion(version: v)
        }
        self.encoding = MDictEncoding(header["encoding"])
        self.delimiter = self.encoding.delimiter
    }

    mutating func scanHeader(headerData: Data) -> [String: String] {
        let u16str: String! = String(data: headerData, encoding: .utf16LittleEndian)
        let regex: Regex = try! Regex(pattern: "(\\w+)=\"(.*?)\"", groupNames: ["key", "value"])
        let match = regex.findAll(in: u16str.htmlUnescape())
        var r: [String: String] = [:]
        match.forEach { m in
            let key: String! = m.group(named: "key")
            let value: String! = m.group(named: "value")
            r[key.lowercased()] = value.lowercased()
        }
        print(r)
        return r
    }

    mutating func readNum<T: FixedWidthInteger>(isLittle: Bool = false) -> T {
        let r: T = self.data.readNum(index: self.index, isLittleEndian: isLittle)
        self.index += T.bitWidth / 8
        return r
    }

    mutating func readInt(isLittle: Bool = false) -> Int {
        switch self.version {
        case .v1:
            let number: UInt32 = self.readNum(isLittle: isLittle)
            return Int(number)
        case .v2:
            let number: UInt64 = self.readNum(isLittle: isLittle)
            return Int(number)
        }
    }

    mutating func readSubRawData(length: Int) -> Data {
        let subData = self.data.subData(self.index, length: length).rawData()
        self.index += length
        return subData
    }

    mutating func readSubData(length: Int, needCheck: Bool = false) -> MDictData {
        let rawData = self.readSubRawData(length: length)
        if needCheck {
            checkAlder32(data: rawData)
        }
        return MDictData(data: rawData, version: self.version, encoding: self.encoding)
    }

    mutating func checkAlder32(data: Data, isLittle: Bool = false) {
        let num: UInt32 = self.readNum(isLittle: isLittle)
        assert(num == data.adler32().checksum & 0xffffffff)
    }

    mutating func decompress(needDecrypt: Bool = false) {
        var compressData = data.rawData()
        if needDecrypt {
            compressData = self.mdxDecrypt(data: compressData)
            self.data = compressData
            self.index = 0
        }
        let adler32: UInt32 = compressData.readNum(index: 4)
        let subData = compressData.subData(8, length: compressData.count - 8)
        if compressData.subData(length: 4).jtBytes == MDictData.compressSignal, let d = subData.unzip() {
            compressData = d
            self.data = compressData
            self.index = 0
        } else {
            compressData = subData
            self.data = compressData
            self.index += 8
        }
        assert(adler32 == compressData.adler32().checksum & 0xffffffff)
    }

    mutating func forwardTextTail() {
        switch self.version {
        case .v1:
            let textHeadSize: UInt8 = self.readNum()
            self.forward(step: self.encoding == .utf8 ? Int(textHeadSize) : Int(textHeadSize) * 2)
            let textTailSize: UInt8 = self.readNum()
            self.forward(step: self.encoding == .utf8 ? Int(textTailSize) : Int(textTailSize) * 2)
        case .v2:
            let textHeadSize: UInt16 = self.readNum()
            self.forward(step: self.encoding == .utf8 ? (Int(textHeadSize) + 1) : (Int(textHeadSize) + 1) * 2)
            let textTailSize: UInt16 = self.readNum()
            self.forward(step: self.encoding == .utf8 ? (Int(textTailSize) + 1) : (Int(textTailSize) + 1) * 2)
        }
    }

    mutating func readWord() -> String {
        let width = delimiter.count
        var i = self.index
        let count = data.count
        var keyEndIndex = count
        while i < count {
            if data.subData(i, length: width).rawData().jtBytes == delimiter {
                keyEndIndex = i
                break
            }
            i += width
        }
        let keyText = self.readString(length: keyEndIndex - index)
        self.forward(step: width)
        return keyText
    }
    
    mutating func readString(length: Int) -> String {
        return String(data: self.readSubRawData(length: length), encoding: .utf8) ?? ""
    }

    mutating func fetchIndexAndWords() -> [(Int, String)] {
        var i = self.index
        var r: [(Int, String)] = []
        let count = data.count
        while i < count {
            let keyId = self.readInt()
            let str = self.readWord()
            i = self.index
            r.append((keyId, str))
        }
        return r
    }
    
    func tailData() -> Data {
        return self.data.subData(self.index, length: self.data.count - self.index).rawData()
    }

    func mdxDecrypt(data: Data) -> Data {
        var keyData = data.subData(4, length: 4)
        let bytes = UInt32(0x3695).data()
        keyData.append(bytes)
        let key: Data = keyData.ripemd128()
        var rData = data.subData(length: 8)
        rData.append(self.fastDecrypt(data: data.subData(8, length: data.count - 8), key: key.jtBytes))
        return rData
    }

    func fastDecrypt(data: Data, key: [UInt8]) -> Data {
        var r = data.jtBytes
        var previous: UInt8 = 0x36
        for i in 0 ..< r.count {
            var t =  (r[i] >> 4 | r[i] << 4) & 0xff
            t = t ^ previous ^ (UInt8(i % 256)) ^ key[i % key.count]
            previous = r[i]
            r[i] = t
        }
        return Data(bytes: r, count: r.count)
    }
}
