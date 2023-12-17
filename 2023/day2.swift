import Foundation
extension StringProtocol {
    var lines: [String] { split(whereSeparator: \.isNewline).map { String($0) } }
}

class Game {
    static let gameNumberRegex = try! Regex("Game ([0-9]+)")
    // use regex to split up our initial input string to group them together
    // an additional regex will be used for each of the input colour types as
    // swift regex doesn't have good support for forward/backward lookups, so trying
    // to use a single regex is eluding me.
    static let gameIterationRegex = try! Regex("[:;] [([0-9]+ [redblugn,])]{1,}")
    static let gameDataRegex = try! Regex("([0-9]+) ([redblugn]+)")
    
    var number: Int
    var tries: [[String: Int]] = []
    init?(from input: String) {
        guard let numberMatch = try? Game.gameNumberRegex.firstMatch(in: input)
              , let gameNumber = Int(numberMatch.output[1].substring!)
               else {
            return nil
        }

        self.number = gameNumber
        
        let reveals = input.matches(of: Game.gameIterationRegex)
        for reveal in reveals {
            var tmp: [String: Int] = [:]
            reveal.output[0].substring?.matches(of: Game.gameDataRegex).forEach { match in
                tmp[String(match.output[2].substring!)] = Int(match.output[1].substring!)
            }
            tries.append(tmp)
        }
    }
}

extension Game {
    func isPossible(baseOn other: Game) -> Bool {
        let impossible = tries.first(where: { iteration in
            for (colour, count) in other.tries[0] {
                if let check = iteration[colour],
                    check > count {
                        return true
                    }
            }
            return false 
        })
        return impossible == nil
    }
}

func unitTestOne() {
    let testinput = """
    Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
    Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
    Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
    Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
    Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
    """.lines.map { Game(from: $0) }

    guard let possible = Game(from: "Game 0: 12 red, 13 green, 14 blue") else {
        print("Unit test game couldn't be parsed!")
        exit(EXIT_FAILURE)
    }

    let validgames = testinput.filter {
        $0!.isPossible(baseOn: possible)
    }.reduce(0, {res, part in 
        return res + part!.number
    })
    guard validgames == 8 else {
        print("Unit Test One failed! expected '8', got '\(validgames)'")
        exit(EXIT_FAILURE)
    }
    print("Unit Test One passed")
}

unitTestOne()

func puzzleOne() {
    let testinput = try! String(contentsOfFile: "day2input.txt").lines.map { Game(from: $0) }
    guard let possible = Game(from: "Game 0: 12 red, 13 green, 14 blue") else {
        print("Puzzle one game couldn't be parsed!")
        exit(EXIT_FAILURE)
    }
    let validgames = testinput.filter {
        $0!.isPossible(baseOn: possible)
    }.reduce(0, {res, part in 
        return res + part!.number
    })
    print("Part 1 Result: \(validgames)")
}

puzzleOne()

extension Game {
    func possiblePower() -> Int {
        var minimums = tries.reduce([String: Int](),{ res, part in 
                var result = res
                for (colour, count) in part {
                    if let lowest = result[colour] {
                        if count > lowest {
                            result[colour] = count
                        }
                    } else {
                        result[colour] = count
                    }
                }
                return result
            })

        return minimums.reduce(1, { res, part in 
                return res * part.value
            })
    }
}

func unitTestTwo() {
    let testinput = """
    Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
    Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
    Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
    Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
    Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
    """.lines.map { Game(from: $0) }

    // let testinput = """
    // Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
    // """.lines.map { Game(from: $0) }

    let power = testinput.reduce(0, { res, part in 
        // print("Adding \(part!.possiblePower())")
        return res + part!.possiblePower()
    })

    guard power == 2286 else {
        print("Unit Test Two failed! Expected '2286', got \(power)")
        exit(EXIT_FAILURE)
    }

    print("Unit Test Two passed!")
}

unitTestTwo()

func puzzleTwp() {
    let testinput = try! String(contentsOfFile: "day2input.txt").lines.map { Game(from: $0) }
    let power = testinput.reduce(0, { res, part in 
        return res + part!.possiblePower()
    })
    print("Part 2 result: \(power)")
}

puzzleTwp()