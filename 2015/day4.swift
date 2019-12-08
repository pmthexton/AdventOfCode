import Foundation
import var CommonCrypto.CC_MD5_DIGEST_LENGTH
import func CommonCrypto.CC_MD5
import typealias CommonCrypto.CC_LONG

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return map { String(format: format, $0) }.joined()
    }
}

func MD5(string: String) -> String {
    let length = Int(CC_MD5_DIGEST_LENGTH)
    let messageData = string.data(using:.utf8)!
    var digestData = Data(count: length)

    _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
        messageData.withUnsafeBytes { messageBytes -> UInt8 in
            if let messageBytesBaseAddress = messageBytes.baseAddress, let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                let messageLength = CC_LONG(messageData.count)
                CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
            }
            return 0
        }
    }

    return digestData.hexEncodedString()
}

func findAdventCoin(with key:String, starts with:String = "00000") -> Int {
    let a = 0
    for a in 0...Int.max {
        let b = key + String(a)
        if MD5(string: b).hasPrefix(with) {
            return a
        }
    }
    return Int.max
}

func p1unitTests() -> Bool {
    let tests = [
        ("abcdef", 609043),
        ("pqrstuv", 1048970)
    ]
    for test in tests {
        guard findAdventCoin(with: test.0) == test.1 else {
            print("Unit test failed. \(test.0) expected \(test.1)")
            return false
        }
        print("Unit test succeeded")
    }
    return true
}

func part1() {
    print("AdventCoin = \(findAdventCoin(with: "yzbqklnj"))")
}
func part2() {
    print("AdventCoin = \(findAdventCoin(with: "yzbqklnj", starts: "000000"))")
}

_ = p1unitTests()
part1()
part2()