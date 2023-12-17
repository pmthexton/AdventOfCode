import Foundation
import Cocoa

extension String {
    // We always expect to be able to get a digit, directly or in word form, as we
    // got the substring from a regex match in the first place
    func getDigit() -> Int {
        if let num = Int(self) {
            return num
        }
        return wordToInteger()
    }
    func wordToInteger() -> Int {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        guard let number = formatter.number(from: self) as? Int else {
            print("Error: converting none-digit word \(self)")
            exit(EXIT_FAILURE)
        }
        return number
    }
}

func get_calibration(from input: [String]) -> Int {
    let numberRegex = try! Regex("one|two|three|four|five|six|seven|eight|nine|[0-9]")
    var foundNumbers: [Int] = []

    // This is horribly inefficient. Native Swift regex seems to have a bug? We can use a positive lookahead
    // to get the correct number of matches, but then trying to extract which value was matched doesn't actually
    // work... Trying to use NSRegularExpression also has a similar problem, we get the correct number of matches
    // but each match object 'range', while having the correct string starting point, appears to have no idea what
    // the end value of the range is, which is probably the underlying cause of the native Swift regex not working
    // For reference, the regex that *should* work to allow us to find all overlapping matches would be:
    // /(?=(one|two|three|four|five|six|seven|eight|nine|ten|[0-9]))/
    // For now, we're going to have to walk through the string subscript and re-run the pattern matching multiple
    // times, grabbing the first match value and then starting the next run at an appropriate substring start point

    input.forEach { line in
        var line_ints: [Int] = []
        var idx = line.startIndex
        while idx <= line.endIndex {
            let substr = line[idx...]

            if let match = substr.firstMatch(of: numberRegex) {
                let found = String(line[match.range])
                line_ints.append(found.getDigit())
                if match.range.lowerBound == line.endIndex {
                    idx = line.endIndex
                } else {
                    idx = line.index(after: match.range.lowerBound)
                }
            } else {
                break
            }
        }
        foundNumbers.append(line_ints.first! * 10 + line_ints.last!)
    }
    return foundNumbers.reduce(0, {res, part in 
      res + part
    })
}

extension StringProtocol {
    var lines: [String] { split(whereSeparator: \.isNewline).map { String($0) } }
}


let test_input_part_1 = """
1abc2
pqr3stu8vwx
a1b2c3d4e5f
treb7uchet
"""
let test_input_part_2 = """
two1nine
eightwothree
abcone2threexyz
xtwone3four
4nineeightseven2
zoneight234
7pqrstsixteen
"""

let test_expected_part_1 = [12, 38, 15, 77]
let test_expected_part_2 = [29, 83, 13, 24, 42, 14, 76]

let test_input_part_1_array = test_input_part_1.lines
let test_input_part_2_array = test_input_part_2.lines
let test_answer_part_1 = test_expected_part_1.reduce(0, { res, part in
    res + part
})
let test_answer_part_2 = test_expected_part_2.reduce(0, { res, part in
    res + part
})

guard test_answer_part_1 == get_calibration(from: test_input_part_1_array) else {
    print("Wrong answer for part 1!")
    exit(EXIT_FAILURE)
}
guard test_answer_part_2 == get_calibration(from: test_input_part_2_array) else {
    print("Wrong answer for part 2!")
    exit(EXIT_FAILURE)
}
print("Unit Test Passed")

let input = try! String(contentsOfFile: "day1input.txt").lines
print("Answer: \(get_calibration(from: input))")
print("if 53551, it's too high")