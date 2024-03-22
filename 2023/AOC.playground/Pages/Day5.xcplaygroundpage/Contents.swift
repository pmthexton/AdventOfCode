//: [Previous](@previous)

import Foundation
import PlaygroundSupport

var data = Utils.loadLines(file: "exampledata")!

guard data[0].starts(with: "seeds: ") else {
    print("Expected seeds line")
    exit(EXIT_FAILURE)
}

func getSeedsRanges(from line: String) -> [Range<Int>] {
    var result: [Range<Int>] = []
    let ints = line.split(separator: " ").compactMap { Int($0 )}
    for idx in stride(from: 0, through: ints.count - 1, by: 2) {
        result.append(ints[idx]..<ints[idx]+ints[idx+1]-1)
    }
    return result
}

struct IntMap {
    let input: Range<Int>
    let output: Range<Int>
}

extension Array where Element == IntMap {
    func contains(_ input: Int) -> Bool {
        for range in self {
            if range.input.contains(input) {
                return true
            }
        }
        return false
    }
    func crossrange(_ input: Range<Int>) {
        self.forEach { range in
//            print("clamped",$0.input.clamped(to: input))
//            print("relative",$0.input.relative(to: input))
            print(input.overlaps(range.input))
        }
    }
}

func getMapRange(from line: String) -> IntMap {
    let ints = line.split(separator: " ").compactMap { Int($0) }
    return IntMap.init(input: ints[1]..<ints[2]-1, output: ints[0]..<ints[2]-1)
}

let seedRanges = getSeedsRanges(from: data.removeFirst())

if data[0].isEmpty {
    _ = data.removeFirst()
}

var seedToSoil: [IntMap] = []
repeat {
    let line = data.removeFirst()
    let ints = line.split(separator: " ").compactMap { Int($0) }
    guard ints.count == 3 else {
        continue
    }
    let inrange = ints[1]..<ints[1]+ints[2]-1
    let outrange = ints[0]..<ints[0]+ints[2]-1
    seedToSoil.append(IntMap.init(input: inrange, output: outrange))
} while !data[0].isEmpty

print(seedToSoil)

// due to zero mapping = same as input rule, let's find the blank ranges and fill them in
for range in seedRanges {
    print("Checking range \(range)")
    seedToSoil.crossrange(range)
}

//: [Next](@next)
