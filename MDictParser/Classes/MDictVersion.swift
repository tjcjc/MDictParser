//
//  MDictVersion.swift
//  MDictParser
//
//  Created by JasonTai on 2019/8/26.
//

enum MDictVersion {
    case v1, v2
    
    init(version: Double) {
        self = version < 2.0 ? .v1 : .v2
    }

    var numBytes: Int {
        switch self {
        case .v1:
            return 4
        case .v2:
            return 8
        }
    }
    
    var textTerm: Int {
        switch self {
        case .v1:
            return 0
        case .v2:
            return 1
        }
    }

    var keyHeaderLen: Int {
        switch self {
        case .v1:
            return 4 * 4
        case .v2:
            return 8 * 5
        }
    }
    
//    func readMDictKeyBlock(data: Data, index: Data.Index, encoding: MdictEncoding) -> (compressSize: Int, decompressSize: Int, count: Int) {
//        switch self {
//        case .v2:
//            let number: UInt64 = data.readNum(index: index)
//        case .v1:
//        }
//    }
}
