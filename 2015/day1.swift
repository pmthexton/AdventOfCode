import Foundation

func getFloor(after moves:String, positionOfBasement: Bool = false) -> Int {
    var floor = 0
    var count = 0
    for move in moves {
        switch(move) {
            case "(":
            floor += 1
            case ")":
            floor -= 1
            default:
            print("Uh-oh")
        }
        count += 1
        if positionOfBasement, floor == -1 {
            return count
        }
    }
    return floor
}

func p1unitTests() -> Bool {
    let tests = [
        ("(())", 0),
        ("()()", 0),
        ("(((", 3),
        ("(()(()(", 3),
        ("))(((((", 3),
        ("())", -1),
        ("))(", -1),
        (")))", -3),
        (")())())", -3)
    ]
    for test in tests {
        guard getFloor(after: test.0) == test.1 else {
            print("Unit test failed. \(test.0) expected floor \(test.1)")
            return false
        }
    }
    return true
}

func p2unitTests() -> Bool {
    let tests = [
        (")", 1),
        ("()())", 5)
    ]
    for test in tests {
        guard getFloor(after: test.0, positionOfBasement: true) == test.1 else {
            print("Unit test failed. \(test.0) expected floor \(test.1)")
            return false
        }
    }
    return true
}

guard p1unitTests(), p2unitTests() else {
    print("Unit Tests failed")
    exit(EXIT_FAILURE)
}

let file = String(data: FileManager.default.contents(atPath: "day1input") ?? Data(), encoding: .utf8)!
print("Part 1:",getFloor(after: file))
print("Part 2:",getFloor(after: file, positionOfBasement: true))