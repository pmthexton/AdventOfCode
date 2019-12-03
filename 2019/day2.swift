import Cocoa
import Foundation

enum OpCode: Int {
    case add = 1, mul = 2, fin = 99

    var nvalues: Int {
        switch(self) {
        case .add:
            return 4
        case .mul:
            return 4
        case .fin:
            return 1
        }
    }

    func perform(_ val1:Int, _ val2:Int) -> Int {
        switch(self) {
            case .add:
                return val1+val2
            case .mul:
                return val1*val2
            case .fin:
                return -1
        }
    }
}

func Run(program:inout [Int]) {
    var idx = 0
    repeat {

        guard let code = OpCode(rawValue: program[idx]) else {
            print("Unkown opcode found")
            break
        }

        if(code == .fin) {
            break
        }

        let res = program[idx+3]

        let val1 = program[program[idx+1]]
        let val2 = program[program[idx+2]]

        program[res] = code.perform(val1, val2)

        idx = idx + code.nvalues

    } while(idx < program.count)
}

func part1_unittest() -> Bool {
    let tests = [
        ([1,9,10,3,2,3,11,0,99,30,40,50], [3500,9,10,70,2,3,11,0,99,30,40,50]),
        ([1,0,0,0,99],[2,0,0,0,99]),
        ([2,3,0,3,99],[2,3,0,6,99]),
        ([2,4,4,5,99,0],[2,4,4,5,99,9801]),
        ([1,1,1,4,99,5,6,0,99],[30,1,1,4,2,5,6,0,99])
    ]

    for test in tests {
        var prog = test.0
        Run(program: &prog)
        guard prog == test.1 else {
            print("Unit tests failed")
            return false
        }
    }
    print("Unit tests passed")
    return true
}

var day2input = [1,12,2,3,1,1,2,3,1,3,4,3,1,5,0,3,2,6,1,19,1,5,19,23,1,13,23,27,1,6,27,31,2,31,13,35,1,9,35,39,2,39,13,43,1,43,10,47,1,47,13,51,2,13,51,55,1,55,9,59,1,59,5,63,1,6,63,67,1,13,67,71,2,71,10,75,1,6,75,79,1,79,10,83,1,5,83,87,2,10,87,91,1,6,91,95,1,9,95,99,1,99,9,103,2,103,10,107,1,5,107,111,1,9,111,115,2,13,115,119,1,119,10,123,1,123,10,127,2,127,10,131,1,5,131,135,1,10,135,139,1,139,2,143,1,6,143,0,99,2,14,0,0]

func part1() {
    var program = day2input
    program[1] = 12
    program[2] = 2

    Run(program: &program)

    print("Part 1 answer = \(program[0])")
}

func part2() {

    var attempts = 0
    let find = 19690720
    for noun in 0...100 {
        for verb in stride(from: 100, to: 1, by: -1) {
            var program = day2input
            program[1] = noun
            program[2] = verb
            attempts += 1

            Run(program: &program)
            if program[0] < find {
                // We're going backwards, if this is too small, so
                // will everything else be
                break
            }

            if program[0] == find {
                print("Part 2 Answer = \(100 * noun + verb)")
                print("\tAnswer found in \(attempts) attempts")
                return
            }
        }
    }

    print("No answer found")
}

guard part1_unittest() else {
    exit(EXIT_FAILURE)
}

part1()
part2()
