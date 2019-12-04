import Foundation

// I would normally have split the int in to a digits Array directly
// with bitwise. But this was quicker to write.
extension String {
    func hasRepeatedChar() -> Bool {
        var lastchar:Character?
        var matchCount = 0
        for char in self {
            if let comp = lastchar {
                if char == comp {
                    matchCount += 1
                } else {
                    if matchCount == 1 {
                        return true
                    }
                    matchCount = 0
                }
            }

            lastchar = char
        }
        return matchCount == 1
    }

    func ascendingDigits() -> Bool {
        let digits = self.map{ Int(String($0))! }
        var sorted = self.map{ Int(String($0))! }
        sorted.sort()

        return digits == sorted
    }

    func isValidPassword() -> Bool {
        return hasRepeatedChar() && ascendingDigits()
    }
}

func unitTests() -> Bool {
    let tests = [
        ("111111", false),
        ("223450", false),
        ("123789", false),
        ("112233", true),
        ("123444", false),
        ("111122", true)
    ]

    for test in tests {
        guard test.0.isValidPassword() == test.1 else {
            print("Test \(test.0) expected \(test.1) failed")
            return false
        }
        print("Test \(test.0) expected \(test.1) passed")
    }

    return true
}

func countMatches() -> Int {
    var inputs:[String] = []
    var matched = 0
    for i in 152085...670283 {
        inputs.append(String(i))
    }
    for input in inputs {
        if input.isValidPassword() {
            matched += 1
        }
    }
    return matched
}

print(unitTests())
print("There are \(countMatches()) matches")
