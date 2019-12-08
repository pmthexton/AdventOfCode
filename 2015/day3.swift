import Foundation

struct Location: Hashable {
    let x: Int
    let y: Int
}

func process(directions: String, _ cb: (Character)->Void) {
    cb("s")
    for char in directions {
        cb(char)
    }
}

enum DeliveryGuy {
    case both, santa, robot
    mutating func toggle() {
        switch(self) {
            case .both:
                self = .santa
            case .santa:
                self = .robot
            case .robot:
                self = .santa
        }
    }
}

func santaAndRobot(directions: String, onmap locations:inout Set<Location>) {
    var driver = DeliveryGuy.both
    var drivers: [DeliveryGuy: (x:Int,y:Int)] = [:]
    drivers[.santa] = (x:0,y:0)
    drivers[.robot] = (x:0,y:0)
    process(directions: directions) {
        if driver == .both {
            locations.insert(Location(x: 0, y: 0))
            driver.toggle()
            return
        }
        switch($0) {
            case "<":
            drivers[driver]!.x -= 1
            case ">":
            drivers[driver]!.x += 1
            case "^":
            drivers[driver]!.y += 1
            case "v":
            drivers[driver]!.y -= 1
            case "s":
            print("At start")
            default:
            print("Uh-oh")
        }
        let newloc = Location(x: drivers[driver]!.x, y: drivers[driver]!.y)
        locations.insert(newloc)
        driver.toggle()
    }
}

func santa(directions: String, onmap locations:inout Set<Location>) {
    var x = 0
    var y = 0
    process(directions: directions) {
        switch($0) {
            case "<":
            x -= 1
            case ">":
            x += 1
            case "^":
            y += 1
            case "v":
            y -= 1
            case "s":
            print("At start")
            default:
            print("Uh-oh")
        }
        locations.insert(Location(x: x, y: y))
    }
}

func p1unitTests() -> Bool {
    let tests = [
        (">", 2),
        ("^>v<", 4),
        ("^v^v^v^v^v", 2)
    ]
    for test in tests {
        var locations = Set<Location>()
        santa(directions: test.0, onmap: &locations)
        guard locations.count == test.1 else {
            print("Test failed. \(test.0) expected \(test.1), got \(locations.count)")
            return false
        }
    }
    return true
}

func p2unitTests() -> Bool {
    let tests = [
        ("^v", 3),
        ("^>v<", 3),
        ("^v^v^v^v^v", 11)
    ]
    for test in tests {
        var locations = Set<Location>()
        santaAndRobot(directions: test.0, onmap: &locations)
        guard locations.count == test.1 else {
            print("Test failed. \(test.0) expected \(test.1), got \(locations.count)")
            return false
        }
    }
    return true
}

let file = String(data: FileManager.default.contents(atPath: "day3input") ?? Data(), encoding: .utf8)!

func part1() {
    var locations = Set<Location>()
    santa(directions: file, onmap: &locations)
    print("Part 1. There were \(locations.count) houses")
}

func part2() {
    var locations = Set<Location>()
    santaAndRobot(directions: file, onmap: &locations)
    print("Part 2. There were \(locations.count) houses")
}

guard p1unitTests(), p2unitTests() else {
    print("Unit tests failed")
    exit(EXIT_FAILURE)
}

part1()
part2()