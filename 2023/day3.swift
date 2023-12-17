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
    func connectedToGear(near: Int) -> [Int] {
        var found: [Int] = []
        self.forEach {
            switch $0 {
                case .partNumber(let partNumber, let bounds, _):
                    if (bounds.0 - 1) <= near,
                        (bounds.1 + 1) >= near {
                            found.append(partNumber)
                        }
                default:
                    _ = 1
            }
        }
        return found
    }

    func hasSymbol(near: Entry) -> Bool {
        // for a possible part number on a vertically adjacent line, see if
        // the x1/x2 values fall within (x1-1)...(x1+1). So long as the min/max of
        // 0 and 9 from the input schematic are honured
        var found = false
        var adjacentTo: (Int, Int)
        switch near {
            case .partNumber(_, let bounds, _):
                adjacentTo = bounds
            default:
                adjacentTo = (-10, -10)
                _ = 1
        }

        self.forEach {
            switch $0 {
                case .symbol(_, let x):
                    if x >= adjacentTo.0 - 1,
                       x <= adjacentTo.1 + 1 {
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
                    symbols.append(Entry.partNumber(partNumber, (x1, x2), false))
                } else {
                    symbols.append(Entry.symbol(String(substr), (x1)))
                }
            }
            return symbols
        }
    }

    func gearRatios() -> [Int] {
        var ratios: [Int] = []
        for (lineIdx, line) in enumerated() {
            for(_, part) in line.enumerated() {
                switch part {
                    case .symbol(let char, let location):
                        guard char == "*" else { continue }
                        var connected = line.connectedToGear(near: location)
                        if lineIdx > 0 {
                            connected.append(contentsOf: self[lineIdx - 1].connectedToGear(near: location))
                        }
                        if lineIdx < self.count - 1 {
                            connected.append(contentsOf: self[lineIdx + 1].connectedToGear(near: location))
                        }
                        guard connected.count == 2 else {
                            print("Gear on line:location \(lineIdx):\(location) connected to \(connected.count) components")
                            continue
                        }
                        ratios.append(connected[0] * connected[1])
                    default:
                        continue
                }
            }
        }
        return ratios 
    }

    func validPartNumbers() -> [Int] {
        var found: [Int] = []
        for (lineIdx, line) in enumerated() {
            var lineEntries: [Int] = []
            for (_, part) in line.enumerated() {
                switch part {
                    case .partNumber(let partNumber, let bounds, _):
                        if line.hasSymbol(near: part) {
                            lineEntries.append(partNumber)
                            continue
                        }
                        if lineIdx > 0 {
                            if self[lineIdx - 1].hasSymbol(near: part) {
                                lineEntries.append(partNumber)
                                continue
                            }
                        }
                        if lineIdx < (self.count - 1) {
                            if self[lineIdx + 1].hasSymbol(near: part) {
                                lineEntries.append(partNumber)
                                continue
                            }
                        }
                    default:
                        _ = 1
                }
            }

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

func UnitTestTwp() {

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
    let answer = entries.gearRatios().reduce(0, { $0 + $1 })
    guard answer == 467835 else {
        print("UnitTestTwo answer of \(answer) failed")
        exit(EXIT_FAILURE)
    }
    print("UnitTestTwo passed")
}

UnitTestTwp()

func PartTwo() {
    let input = try! String(contentsOfFile: "day3input.txt").lines
    let entries = [[Entry]].init(from: input)
    let ratios = entries.gearRatios()
    // print(validParts)
    let answer = ratios.reduce(0, {$0 + $1})

    guard answer == 86841457 else {
        print("\(answer) is wrong. you've broken your implementation. git-revert!")
        exit(EXIT_FAILURE)
    }
    
    print("Part Two Answer: \(answer)")
}

PartTwo()