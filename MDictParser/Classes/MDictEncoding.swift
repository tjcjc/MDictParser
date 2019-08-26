//
//  MDictEncoding.swift
//  MDictParser
//
//  Created by JasonTai on 2019/8/27.
//

enum MDictEncoding {
    case utf8, utf16

    init(_ string: String?) {
        if let str = string {
            if str.lowercased() == "utf-16" {
                self = .utf16
            } else {
                self = .utf8
            }
        } else {
            self = .utf8
        }
    }

    var delimiter: [UInt8] {
        switch self {
        case .utf8:
            return [0]
        case .utf16:
            return [0, 0]
        }
    }
}
