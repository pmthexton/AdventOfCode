//: [Previous](@previous)

import Foundation
import XCTest

struct race {
    let length: Int
    let distance: Int
    func winningStrategies() -> Int {
        var result = 0
        // find the shortest hold time to beat the record
        var shortest = 0
        var holdRange = 1...length-1

        repeat {
            var mid = holdRange.lowerBound + Int(floor(Double((holdRange.upperBound - holdRange.lowerBound)/2)))

            if mid * (length - mid) > distance {
                holdRange = holdRange.lowerBound...mid
            } else {
                holdRange = mid...holdRange.upperBound
            }
            if holdRange.count == 2 {
                if holdRange.upperBound * (length - holdRange.upperBound) > distance {
                    shortest = holdRange.upperBound
                } else {
                    print("Could not find the smallest winning value after starting at middle!")
                    exit(EXIT_FAILURE)
                }
            }
        } while shortest == 0

        var longest = 0
        holdRange = 1...length-1
        repeat {
            var mid = holdRange.lowerBound + Int(floor(Double((holdRange.upperBound - holdRange.lowerBound)/2)))
            if mid * (length - mid) > distance {
                holdRange = mid...holdRange.upperBound
            } else {
                holdRange = holdRange.lowerBound...mid
            }
            if holdRange.count == 2 {
                if holdRange.lowerBound * (length - holdRange.lowerBound) > distance {
                    longest = holdRange.lowerBound
                } else {
                    print("Could not find the longest winning value after starting at middle!")
                    exit(EXIT_FAILURE)
                }
            }
        } while longest == 0
        result = (shortest...longest).count

        return result
    }
}

//
//for race in part1races {
//    print(race.winningStrategies())
//}

class TestCase: XCTestCase {
    let inputfilename = "puzzleinput"
    
    func testPart1() {
        let part1rows = Utils.loadLines(file: self.inputfilename)!.filter {
            !$0.isEmpty
        }.compactMap {
            $0.split(separator: " ").compactMap { Int($0) }
        }

        let part1races = part1rows[0].indices.map {
            race.init(length: part1rows[0][$0], distance: part1rows[1][$0])
        }
        
        let test: XCTMeasureOptions = XCTMeasureOptions()
        test.iterationCount = 0
        measure(options: test) {
            let answer = part1races[1..<part1races.count].reduce(part1races[0].winningStrategies(), { answer, race in
                return answer * race.winningStrategies()
            })
            print("Part 1:",answer)
        }
    }
    
    func testPart2() {
        let part2rows = Utils.loadLines(file: self.inputfilename)!.filter {
            !$0.isEmpty
        }.compactMap {
            $0.replacingOccurrences(of: " ", with: "").split(separator: ":").compactMap { Int($0) }
        }.compactMap { $0[0] }
//        print(part2rows)
        let race = race.init(length: part2rows[0], distance: part2rows[1])
        let test: XCTMeasureOptions = XCTMeasureOptions()
        test.iterationCount = 0
        measure(options: test) {
            let result = race.winningStrategies()
            print("Part 2:",result)
        }
    }
}

TestCase.defaultTestSuite.run()

//: [Next](@next)
