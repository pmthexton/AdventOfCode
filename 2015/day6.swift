
import Foundation
import NaturalLanguage

let file = String(data: FileManager.default.contents(atPath: "day6input") ?? Data(), encoding: .utf8)!

extension String {
    func matches(re regex:NSRegularExpression) -> [String] {
        var matches: [String] = []
        
        let range = NSRange(location: 0, length: self.utf16.count)
        
        let found = regex.matches(in: self, options: [], range: range)
        
        for match in found {
            for i in 1..<match.numberOfRanges {
                if let mrange = Range(match.range(at: i), in: self) {
                    matches.append(String(self[mrange]))
                }
            }
        }
        
        return matches
    }
    
    func matches(pattern re:String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: re) else {
            return []
        }
        
        return matches(re: regex)
    }
}


// These are duplicated because Swift explicitly doesn't support overlapping conformances.
// Informative thread here:
// https://stackoverflow.com/questions/57282655/why-there-cannot-be-more-than-one-conformance-even-with-different-conditional
extension Array where Element == [Bool] {
    mutating func perform(command:Command) -> Void {
        for n in command.xrange[0]...command.xrange[1] {
            for y in command.yrange[0]...command.yrange[1] {
                self[n][y].command(command.cmd)
            }
        }
    }
}
extension Array where Element == [Int] {
    mutating func perform(command:Command) -> Void {
        for n in command.xrange[0]...command.xrange[1] {
            for y in command.yrange[0]...command.yrange[1] {
                self[n][y].command(command.cmd)
            }
        }
    }
}


extension Bool {
    mutating func command(_ cmd:String) {
        switch(cmd) {
            case "on":
                self = true
            case "off":
                self = false
            case "toggle":
                toggle()
            default:
                print("Unexpected command \(cmd)")
        }
    }
}

extension Int {
    mutating func command(_ cmd:String) {
        switch(cmd) {
        case "on":
            self += 1
        case "off":
            if self > 0 {
                self -= 1
            }
        case "toggle":
            self += 2
        default:
            print("Unexpected command \(cmd)")
        }
    }
}

struct Command {
    var cmd:String
    var xrange:[Int]
    var yrange:[Int]
    
    init?(from str:String) {
        cmd = ""
        xrange = []
        yrange = []
        for token in str.components(separatedBy: " ") {
            if ["turn","through"].contains(token) { // syntactic sugar. ignore.
                continue
            }
            if cmd.isEmpty {
                if !["on","off","toggle"].contains(token) {
                    print("Unexpected token \(token). Expected one of [on,off,toggle]")
                    return nil
                }
                cmd = token
                continue
            }
            guard let regex = try? NSRegularExpression(pattern: "([0-9]{1,3}),([0-9]{1,3})") else {
                print("Unable to create regex to parse light array definition")
                return nil
            }
            let values = token.matches(re: regex)
            if values.count == 2 {
                xrange.append(Int(values[0])!)
                yrange.append(Int(values[1])!)
            }
        }
    }
}

func part1() {
    var lights = Array(repeating: Array(repeating: false, count: 1000), count: 1000)

    let commands = file.components(separatedBy: "\n").map { Command(from: $0)! }

    commands.forEach { command in
        lights.perform(command:command)
    }

    let count = lights.reduce(0) { w, x in
        w + x.reduce(0) { y, z in 
            y + (z ? 1 : 0)
        }
    }

    print("Part 1: \(count) lights are lit")
}

func part2() {
    var lights = Array(repeating: Array(repeating: 0, count: 1000), count: 1000)

    let commands = file.components(separatedBy: "\n").map { Command(from: $0)! }

    commands.forEach { command in
        lights.perform(command:command)
    }

    let brightness = lights.reduce(0) { w, x in 
        w + x.reduce(0) { y, z in 
            y + z
        }
    }

    print("Part 2: brightness = \(brightness)")
}

part1()
part2()