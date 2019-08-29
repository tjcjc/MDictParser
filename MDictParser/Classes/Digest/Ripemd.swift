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

public final class Ripemd: DigestType {
    let variant: Variant
    let digestLength: Int
    static let blockSize: Int = 64

    public enum Variant: RawRepresentable {
        case ripemd128, ripemd160

        public var digestLength: Int {
            return rawValue / 8
        }
        
        public var blockSize: Int {
            return rawValue / 2 - 1
        }
        
        public var hash: [UInt32] {
            switch self {
            case .ripemd160:
                return [0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0]
            case .ripemd128:
                return [0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476]
            }
        }

        public typealias RawValue = Int
        public var rawValue: RawValue {
            switch self {
            case .ripemd128:
                return 128
            case .ripemd160:
                return 160
            }
        }

        public init?(rawValue: RawValue) {
            switch rawValue {
            case 128:
                self = .ripemd128
                break
            case 160:
                self = .ripemd160
                break
            default:
                return nil
            }
        }
    }

    public init(variant: Ripemd.Variant) {
        self.variant = variant
        self.digestLength = variant.digestLength
    }

    public func calculate(for bytes: Array<UInt8>) -> Array<UInt8> {
        var accumulatedHash = variant.hash
        let accumulated = padding(for: bytes)
        
        for chunk in accumulated.batched(by: Ripemd.blockSize) {
            variant.compress(message: convertToUInt32Array(Array(chunk)), hash: &accumulatedHash)
        }
         
        return (NSData(bytes: accumulatedHash, length: self.digestLength) as Data).jtBytes
    }
    
    func convertToUInt32Array(_ chunk: Array<UInt8>) -> Array<UInt32> {
        var words: [UInt32] = Array(repeating: UInt32(0), count: Ripemd.blockSize / 4)
        NSData(bytes: chunk, length: chunk.count).getBytes(&words, length: Ripemd.blockSize)
        return words
    }
    
    func padding(for bytes: Array<UInt8>) -> Array<UInt8> {
        var accumulated: [UInt8] = bytes

        let lengthInBits : [UInt32] = [UInt32(accumulated.count) * 8, 0]
        let lengthBytes = NSData(bytes: lengthInBits, length: Ripemd.blockSize / 8)
        
        // Step 1. Append padding
        bitPadding(to: &accumulated, blockSize: Ripemd.blockSize, allowance: Ripemd.blockSize / 8)
        
        // Step 2. Append Length a 64-bit representation of lengthInBits
        accumulated += lengthBytes
        return accumulated
    }
    
}


