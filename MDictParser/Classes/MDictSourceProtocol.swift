//
//  MDictSourceProtocol.swift
//  MDictParser
//
//  Created by JasonTai on 2019/8/27.
//


public protocol MDictSourceProtocol {
    var count: Int { get }
    func subData(_ start: Int, length: Int) -> Self
    func subData(length: Int) -> Self
    func readNum<T: FixedWidthInteger>(index: Int, isLittleEndian: Bool) -> T
    func readNum<T: FixedWidthInteger>(index: Int) -> T
    func readNum<T: FixedWidthInteger>(isLittleEndian: Bool) -> T
    func readNum<T: FixedWidthInteger>() -> T
    func rawData() -> Data
}

extension MDictSourceProtocol {
    public func subData(length: Int) -> Self {
        return subData(0, length: length)
    }
    
    public func readNum<T: FixedWidthInteger>(isLittleEndian: Bool) -> T {
        return readNum(index: 0, isLittleEndian: isLittleEndian)
    }
    
    public func readNum<T: FixedWidthInteger>(index: Int) -> T {
        return readNum(index: index, isLittleEndian: false)
    }
    
    public func readNum<T: FixedWidthInteger>() -> T {
        return readNum(index: 0, isLittleEndian: false)
    }
}

extension Data: MDictSourceProtocol {
    public func rawData() -> Data {
        return self
    }
}
