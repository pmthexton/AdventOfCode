//: [Previous](@previous)

import Foundation

struct Vertex {
    let left: String
    let right: String
    
    init(left: Substring, right: Substring) {
        self.left = String(left)
        self.right = String(right)
    }
}

var map: [String: Vertex] = [:]

//var input = """
//LR
//
//11A = (11B, XXX)
//11B = (XXX, 11Z)
//11Z = (11B, XXX)
//22A = (22B, XXX)
//22B = (22C, 22C)
//22C = (22Z, 22Z)
//22Z = (22B, 22B)
//XXX = (XXX, XXX)
//""".split(separator: "\n")
var input = Utils.loadLines(file: "puzzleinput")!

let directions = input.removeFirst()

let r = /([A-Z1-9]{3}) = \(([A-Z1-9]{3}), ([A-Z1-9]{3})\)/

for line in input {
    if line.isEmpty {
        continue
    }
    let rmatch = line.matches(of: r)
    guard let match = rmatch.first else {
        print("Error parsing line [\(line)]")
        exit(EXIT_FAILURE)
    }
    map[String(match.1)] = Vertex(left: match.2, right: match.3)
}

extension Int {
    func gcdIterativeEuklid(_ n: Int) -> Int {
        var a: Int = 0
        var b: Int = Swift.max(self, n)
        var r: Int = Swift.min(self, n)

        while r != 0 {
            a = b
            b = r
            r = a % b
        }
        return b
    }
}

extension Dictionary where Iterator.Element == (key: String, value: Vertex) {
    func steps(from startpoint: String) -> Int {
        var count = 0
        var idx = startpoint
        
        repeat {
            for turn in directions {
                switch String(turn) {
                case "L":
                    idx = self[idx]!.left
                case "R":
                    idx = self[idx]!.right
                default:
                    print("something wrong here")
                    exit(EXIT_FAILURE)
                }
                count += 1
                if idx.hasSuffix("Z") {
                    break
                }
            }
        } while !idx.hasSuffix("Z")
        
        return count
    }
    func solvePart1() {
        var found = false
        var idx = "AAA"
        var count = 0
        repeat {
            for turn in directions {
                switch String(turn) {
                case "L":
                    guard self.keys.contains(idx) else {
                        print("Oh... \(idx)")
                        exit(EXIT_FAILURE)
                    }
                    idx = self[idx]!.left
                case "R":
                    idx = self[idx]!.right
                default:
                    print("Unknown direction found \(String(turn))")
                    exit(EXIT_FAILURE)
                }
                count += 1
                if idx == "ZZZ" {
                    break
                }
            }
        } while idx != "ZZZ"

        print("Answer: ",count)
    }
    
    func solvePart2() {
        let cur = self.keys.filter { $0.hasSuffix("A") }
        let iterations = cur.map { self.steps(from: $0) }
        print(iterations)
        let leastCommonMultiple = iterations.reduce(0, { res, n in
            if res == 0 {
                return n
            }
            return res * n / res.gcdIterativeEuklid(n)
        })
        print("Answer:",leastCommonMultiple)
//        for point in cur {
//            print(point,self.steps(from: point))
//        }
    }
    
    func oldSolvePart2() {
        var cur = self.keys.filter { $0.hasSuffix("A") }
        let ends = self.keys.filter { $0.hasSuffix("Z") }
        var found = false
        var count = 0
        guard cur.count == ends.count else {
            print("Invalid data - \(cur.count) != \(ends.count)")
            exit(EXIT_FAILURE)
        }
        print("Starting at \(cur)")
        repeat {
            for turn in directions {
                cur = cur.map {
                    switch turn {
                    case "L":
                        return self[$0]!.left
                    case "R":
                        return self[$0]!.right
                    default:
                        print("Unknown direction found \(turn)")
                        exit(EXIT_FAILURE)
                    }
                }
                count += 1
                if cur.filter({ $0.hasSuffix("Z") }).count == cur.count {
                    found = true
                }
            }
        } while found == false
        print("Answer:",count)
    }
}

map.solvePart1()
map.solvePart2()

//: [Next](@next)
