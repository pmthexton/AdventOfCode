import Foundation
import RegexBuilder

extension StringProtocol {
    var lines: [String] { split(whereSeparator: \.isNewline).map { String($0) } }
}

let regex = try! Regex("[0-9]+|[^.]")

enum Entry {
    case partNumber(Int, (Int, Int), Bool)
    case symbol(String, (Int))
}

extension Array where Element == Entry {
    func hasSymbol(near: Entry) -> Bool {
        // for a possible part number on a vertically adjacent line, see if
        // the x1/x2 values fall within (x1-1)...(x1+1). So long as the min/max of
        // 0 and 9 from the input schematic are honured
        var found = false
        var value: Int = 0
        var adjacentTo: (Int, Int)
        switch near {
            case .partNumber(let val, let bounds, _):
                value = val
                adjacentTo = bounds
            default:
                adjacentTo = (-10, -10)
                _ = 1
        }

        self.forEach {
            switch $0 {
                case .symbol(let char, let x):
                    if x >= adjacentTo.0 - 1,
                       x <= adjacentTo.1 + 1 {
                        // print("\(adjacentTo.0 - 1) > \(x) < \(adjacentTo.1 + 1)")
                        // if value == 234 {
                        //     print("Adding 234 based on char \(char) at index \(x), input range \(adjacentTo)")
                        // }
                        found = true
                        break
                    }
                default:
                    _ = 1
            }
        }
        return found
    }
}

extension Array where Element == [Entry] {
    init(from input: [String]) {
        self = input.map {
            var symbols: [Entry] = []
            let matches = $0.matches(of: regex)
            for match in matches {
                guard let substr = match.output.first?.substring,
                    let lowerBound = match.output.first?.range?.lowerBound,
                    let upperBound = match.output.first?.range?.upperBound else {
                    continue
                }
                let x1 = $0.distance(from: $0.startIndex, to: lowerBound)
                // I don't know if there's something I'm missing here, but
                // asking for the distance to the end of the matched entry, there
                // seems to be an off-by-one (positive) error, where-as the start
                // index is fine. shrug.
                let x2 = $0.distance(from: $0.startIndex, to: upperBound) - 1
                if let partNumber = Int(substr) {
                    // if partNumber == 234 {
                    //     print("Creating 234 based on \(x1)-\(x2) and substr \(substr)")
                    // }
                    symbols.append(Entry.partNumber(partNumber, (x1, x2), false))
                } else {
                    symbols.append(Entry.symbol(String(substr), (x1)))
                }
            }
            return symbols
        }
    }

    func validPartNumbers() -> [Int] {
        var found: [Int] = []
        for (lineIdx, line) in enumerated() {
            var lineEntries: [Int] = []
            for (_, part) in line.enumerated() {
                switch part {
                    case .partNumber(let partNumber, let bounds, _):
                        if line.hasSymbol(near: part) {
                            // if partNumber == 234 {
                            //     print("Adding 234 from same line analysis")
                            // }
                            lineEntries.append(partNumber)
                            continue
                        }
                        if lineIdx > 0 {
                            if self[lineIdx - 1].hasSymbol(near: part) {
                                // if partNumber == 234 {
                                // print("Adding 234 from previous line analysis")
                                // }
                                lineEntries.append(partNumber)
                                continue
                            }
                        }
                        // print("\(lineIdx) is less than \(self.count) ?)")
                        if lineIdx < (self.count - 1) {
                            // if partNumber == 234 {
                            //     print("Adding 234 from next line analysis")
                            //     }
                            if self[lineIdx + 1].hasSymbol(near: part) {
                                lineEntries.append(partNumber)
                                continue
                            }
                        }
                    default:
                        _ = 1
                }
            }
            // if lineIdx == 87 {
            //     print("Adding: \(lineEntries)")
            // }
            found.append(contentsOf: lineEntries)
        }

        return found 
    }
}

func UnitTestOne() {

    let input = """
    467..114..
    ...*......
    ..35..633.
    ......#...
    617*......
    .....+.58.
    ..592.....
    ......755.
    ...$.*....
    .664.598..
    """.lines 

    let entries = [[Entry]].init(from: input)
    
    guard entries.validPartNumbers().reduce(0, { $0 + $1 }) == 4361 else {
        print("UnitTestOne failed")
        exit(EXIT_FAILURE)
    }
    print("UnitTestOne passed")
}

UnitTestOne()

func PartOne() {
    let input = try! String(contentsOfFile: "day3input.txt").lines
    let entries = [[Entry]].init(from: input)
    let validParts = entries.validPartNumbers()
    // print(validParts)
    let partSum = validParts.reduce(0, {$0 + $1})

    guard partSum == 559667 else {
        print("\(partSum) is wrong. you've broken your implementation. git-revert!")
        exit(EXIT_FAILURE)
    }
    
    print("Part One Answer: \(partSum)")
}

PartOne()

