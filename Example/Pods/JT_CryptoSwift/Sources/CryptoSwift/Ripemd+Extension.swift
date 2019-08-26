////  CryptoSwift
//
//  Copyright (C) 2014-__YEAR__ Marcin Krzyżanowski <marcin@krzyzanowskim.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//

infix operator  ~<< : MultiplicationPrecedence

public func ~<< (lhs: UInt32, rhs: Int) -> UInt32 {
    return (lhs << UInt32(rhs)) | (lhs >> UInt32(32 - rhs));
}

extension Ripemd.Variant {
    public func compress(message: [UInt32], hash: inout [UInt32]) {
        var leftHash = hash
        var rightHash = hash
        let leftSide = Side.Left
        let rightSide = Side.Right
        for index in 0...self.blockSize {
            compressRoundBySide(message: message, index: index, hash: &leftHash, side: leftSide)
            compressRoundBySide(message: message, index: index, hash: &rightHash, side: rightSide)
        }
        
        switch self {
        case .ripemd160:
            let T = hash[1] &+ leftHash[2] &+ rightHash[3]
            hash[1] = hash[2] &+ leftHash[3] &+ rightHash[4]
            hash[2] = hash[3] &+ leftHash[4] &+ rightHash[0]
            hash[3] = hash[4] &+ leftHash[0] &+ rightHash[1]
            hash[4] = hash[0] &+ leftHash[1] &+ rightHash[2]
            hash[0] = T
        case .ripemd128:
            let T = hash[1] &+ leftHash[2] &+ rightHash[3]
            hash[1] = hash[2] &+ leftHash[3] &+ rightHash[0]
            hash[2] = hash[3] &+ leftHash[0] &+ rightHash[1]
            hash[3] = hash[0] &+ leftHash[1] &+ rightHash[2]
            hash[0] = T
        }
    }
    
    public func compressRoundBySide(message: [UInt32], index: Int, hash: inout [UInt32], side: Side) {
        let word = message[side.r(j: index)]
        let function = side == .Left ? f(j: index) : f(j: self.blockSize - index)
        var T: UInt32 = ((hash[0] &+ function(hash[1], hash[2], hash[3]) &+ word &+ side.K(j: index, v: self)) ~<< side.s(j: index))
        
        switch self {
        case .ripemd128:
            hash[0] = hash[3]
            hash[3] = hash[2]
            hash[2] = hash[1]
            hash[1] = T
        case .ripemd160:
            T = T &+ hash[4]
            hash[1] = hash[4]
            hash[4] = hash[3]
            hash[3] = hash[2] ~<< 10
            hash[2] = hash[1]
            hash[1] = T
        }
    }

    public func f (j: Int) -> ((UInt32, UInt32, UInt32) -> UInt32) {
        switch index {
        case _ where j < 0:
            assert(false, "Invalid j")
            return {(_, _, _) in 0 }
        case _ where j <= 15:
            return {(x, y, z) in  x ^ y ^ z }
        case _ where j <= 31:
            return {(x, y, z) in  (x & y) | (~x & z) }
        case _ where j <= 47:
            return {(x, y, z) in  (x | ~y) ^ z }
        case _ where j <= 63:
            return {(x, y, z) in  (x & z) | (y & ~z) }
        case _ where j <= 79:
            return {(x, y, z) in  x ^ (y | ~z) }
        default:
            assert(false, "Invalid j")
            return {(_, _, _) in 0 }
        }
    }
    
    public enum Side {
        case Left, Right
        
        func s(j: Int) -> Int {
            switch j {
            case _ where j < 0:
                assert(false, "Invalid j")
                return 0
            case _ where j <= 15:
                return (self == .Left ? [11,14,15,12,5,8,7,9,11,13,14,15,6,7,9,8] : [8,9,9,11,13,15,15,5,7,7,8,11,14,14,12,6])[j]
            case _ where j <= 31:
                return (self == .Left ? [7,6,8,13,11,9,7,15,7,12,15,9,11,7,13,12] : [9,13,15,7,12,8,9,11,7,7,12,7,6,15,13,11])[j - 16]
            case _ where j <= 47:
                return (self == .Left ? [11,13,6,7,14,9,13,15,14,8,13,6,5,12,7,5] : [9,7,15,11,8,6,6,14,12,13,5,14,13,13,7,5])[j - 32]
            case _ where j <= 63:
                return (self == .Left ? [11,12,14,15,14,15,9,8,9,14,5,6,8,6,5,12] : [15,5,8,11,14,14,6,14,6,9,12,9,12,5,15,8])[j - 48]
            case _ where j <= 79:
                return (self == .Left ? [9,15,5,11,6,8,13,12,5,12,13,14,11,8,5,6] : [8,5,12,9,12,5,14,6,8,13,6,5,15,13,11,11])[j - 64]
            default:
                assert(false, "Invalid j")
                return 0
            }
        }
        
        func r(j: Int) -> Int {
            switch j {
            case _ where j < 0:
                assert(false, "Invalid j")
                return 0
            case let index where j <= 15:
                if self == .Left {
                    return index
                } else {
                    return [5,14,7,0,9,2,11,4,13,6,15,8,1,10,3,12][index]
                }
            case let index where j <= 31:
                if self == .Left {
                    return [ 7, 4,13, 1,10, 6,15, 3,12, 0, 9, 5, 2,14,11, 8][index - 16]
                } else {
                    return [ 6,11, 3, 7, 0,13, 5,10,14,15, 8,12, 4, 9, 1, 2][index - 16]
                }
            case let index where j <= 47:
                if self == .Left {
                    return [3,10,14,4,9,15,8,1,2,7,0,6,13,11,5,12][index - 32]
                } else {
                    return [15,5,1,3,7,14,6,9,11,8,12,2,10,0,4,13][index - 32]
                }
            case let index where j <= 63:
                if self == .Left {
                    return [1,9,11,10,0,8,12,4,13,3,7,15,14,5,6,2][index - 48]
                } else {
                    return [8,6,4,1,3,11,15,0,5,12,2,13,9,7,10,14][index - 48]
                }
            case let index where j <= 79:
                if self == .Left {
                    return [ 4,0,5,9,7,12,2,10,14,1,3,8,11,6,15,13][index - 64]
                } else {
                    return [12,15,10,4,1,5,8,7,6,2,13,14,0,3,9,11][index - 64]
                }
                
            default:
                assert(false, "Invalid j")
                return 0
            }
        }
        
        func K(j: Int, v: Ripemd.Variant) -> UInt32 {
            switch j {
            case _ where j < 0:
                assert(false, "Invalid j")
                return 0
            case _ where j <= 15:
                return self == .Left ? 0x00000000 : 0x50A28BE6
            case _ where j <= 31:
                return self == .Left ? 0x5A827999 : 0x5C4DD124
            case _ where j <= 47:
                return self == .Left ? 0x6ED9EBA1 : 0x6D703EF3
            case _ where j <= 63:
                return self == .Left ? 0x8F1BBCDC : ( v == .ripemd128 ? 0x00000000 : 0x7A6D76E9 )
            case _ where j <= 79:
                return self == .Left ? 0xA953FD4E : 0x00000000
            default:
                assert(false, "Invalid j")
                return 0
            }
        }
    }
}

extension Digest {
    /// Calculate Ripemd Digest
    /// - parameter bytes: input message
    /// - parameter variant: SHA-3 variant
    /// - returns: Digest bytes
    public static func ripemd(_ bytes: Array<UInt8>, variant: Ripemd.Variant) -> Array<UInt8> {
        return Ripemd(variant: variant).calculate(for: bytes)
    }
    
    
    /// Calculate Ripemd Digest
    /// - parameter bytes: input message
    /// - returns: Digest bytes
    public static func ripemd128(_ bytes: Array<UInt8>) -> Array<UInt8> {
        return Digest.ripemd(bytes, variant: .ripemd128)
    }
    
    /// Calculate Ripemd Digest
    /// - parameter bytes: input message
    /// - returns: Digest bytes
    public static func ripemd160(_ bytes: Array<UInt8>) -> Array<UInt8> {
        return Digest.ripemd(bytes, variant: .ripemd160)
    }
}

extension Data {
    public func ripemd128() -> Data {
        return Data(Digest.ripemd128(bytes))
    }
    
    public func ripemd160() -> Data {
        return Data(Digest.ripemd160(bytes))
    }
}
