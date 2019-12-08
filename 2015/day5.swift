import Cocoa

extension String {
    var hasDuplicatePair: Bool {
        var char:Character?
        for a in self {
            if char != nil {
                if a == char {
                    return true
                }
            }
            char = a
        }
        return false
    }

    var hasSeparatedDuplicate: Bool {
        for (n,c) in self.enumerated() {
            if n < self.count-2 {
                let idx = self.index(self.startIndex, offsetBy: n+2)
                if c == self[idx] {
                    return true
                }
            }
        }
        return false
    }

    var hasNoneOverlappingPair: Bool {
        var pairs: [String] = []
        var duplicates = Set<String>()

        for n in 0..<self.count-1 {
            let i = self.index(self.startIndex, offsetBy: n)
            let j = self.index(self.startIndex, offsetBy: n+1)
            let str = String(self[i...j])
            if pairs.contains(str) {
                duplicates.insert(str)
            }
            pairs.append(str)
        }
        duplicates = duplicates.filter({
            if $0[$0.startIndex] == $0[$0.index($0.startIndex, offsetBy: 1)] {
                let str = String($0[$0.startIndex])
                let lookup = str + str + str
                if self.contains(lookup) {
                    return self.contains(lookup + str)
                }
            }
            return true
        })
        return duplicates.count > 0 ? true : false
    }

    var isBlacklisted: Bool {
        let blacklist: [String] = ["ab","cd","pq","xy"]
        for a in blacklist {
            if self.contains(a) {
                return true
            }
        }
        return false
    }

    var hasThreeVowels: Bool {
        let vowels: [Character] = ["a","e","i","o","u"]
        return self.filter({ vowels.contains($0) }).count >= 3
    }
}

func nice1(name: String) -> Bool {

    guard name.hasThreeVowels,
        name.hasDuplicatePair,
        !name.isBlacklisted else {
        return false
    }
    return true
}

func nice2(name: String) -> Bool {
    guard name.hasNoneOverlappingPair,
        name.hasSeparatedDuplicate else {
            return false
        }
    return true
}

func p1unitTests() -> Bool {
    let tests = [
        ("ugknbfddgicrmopn", true),
        ("aaa", true),
        ("jchzalrnumimnmhp", false),
        ("haegwjzuvuyypxyu", false),
        ("dvszwmarrgswjxmb", false)
    ]
    for test in tests {
        guard nice1(name: test.0) == test.1 else {
            print("Test failed. \(test.0) expected \(test.1)")
            return false
        }
    }
    return true
}

func p2unitTests() -> Bool {
    let tests = [
        ("qjhvhtzxzqqjkmpb", true),
        ("xxyxx", true),
        ("abgenab", false),
        ("abgenaba", true),
        ("uurcxstgmygtbstg", false),
        ("ieodomkazucvgmuy", false)
    ]
    for test in tests {
        guard nice2(name: test.0) == test.1 else {
            print("Test failed. \(test.0) expected \(test.1)")
            return false
        }
    }

    return true
}

let file = String(data: FileManager.default.contents(atPath: "day5input") ?? Data(), encoding: .utf8)!

func part1() {
    var count = 0
    for name in file.components(separatedBy: "\n") {
        if nice1(name: name) {
            count += 1
        }
    }
    print("Part 1: There are \(count) nice names")
}

func part2() {
    var count = 0
    for name in file.components(separatedBy: "\n") {
        if nice2(name: name) {
            count += 1
        }
    }
    print("Part 2: There are \(count) nice names")
}

print(p1unitTests())
print(p2unitTests())
print("Tests passed")

part1()
part2()