import Foundation

struct Dimensions {
    let l: Int
    let w: Int
    let h: Int
    let s: Int
    init(_ str:String) {
        let chars = str.components(separatedBy: "x")
        l=Int(chars[0])!
        w=Int(chars[1])!
        h=Int(chars[2])!
        s=[l*w,w*h,h*l].min()!
    }

    func calculateWrappingRequired() -> Int {
        let s1 = (l*w)*2
        let s2 = (w*h)*2
        let s3 = (h*l)*2

        return (s1 + s2 + s3 + s)
    }

    func calculateRibbonRequired() -> Int {
        let smallest = [2*w+2*h,2*h+2*l,2*w+2*l].min()!
        return smallest + l*w*h
    }
}

func p1unitTests() -> Bool {
    let tests = [
        ("2x3x4", 58),
        ("1x1x10", 43)
    ]
    for test in tests {
        let dim = Dimensions(test.0)
        guard dim.calculateWrappingRequired() == test.1 else {
            print("Test failed. \(test.0) expected \(test.1)")
            print("Got value \(dim.calculateWrappingRequired())")
            return false
        }
    }
    return true
}

func p2unitTests() -> Bool {
    let tests = [
        ("2x3x4", 34),
        ("1x1x10", 14)
    ]
    for test in tests {
        let dim = Dimensions(test.0)
        guard dim.calculateRibbonRequired() == test.1 else {
            print("Test failed. \(test.0) expected \(test.1)")
            print("Got value \(dim.calculateRibbonRequired())")
            return false
        }
    }
    return true
}

let file = String(data: FileManager.default.contents(atPath: "day2input") ?? Data(), encoding: .utf8)!

func part1() {
    var required = 0
    for line in file.components(separatedBy: "\n") {
        let dim = Dimensions(line)
        required += dim.calculateWrappingRequired()
    }
    print("Part 1 wrapping required \(required)")
}

func part2() {
    var required = 0
    for line in file.components(separatedBy: "\n") {
        let dim = Dimensions(line)
        required += dim.calculateRibbonRequired()
    }
    print("Part 2 ribbon required \(required)")
}

guard p1unitTests(), p2unitTests() else {
    print("Unit tests failed")
    exit(EXIT_FAILURE)
}

print("Tests passed")
part1()
part2()