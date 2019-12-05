import Foundation

enum ParameterMode: Int {
    case position = 0, immediate = 1
}

enum OpCode: Int {
    case err = -1,
         add = 1, mul = 2, input = 3,
         output = 4, jumpiftrue = 5,
         jumpiffalse = 6, lessthan = 7,
         equals = 8, fin = 99

    var nvalues: Int {
        switch(self) {
        case .err:
            return 0
        case .add:
            return 4
        case .mul:
            return 4
        case .input:
            return 2
        case .output:
            return 2
        case .jumpiftrue:
            return 3
        case .jumpiffalse:
            return 3
        case .lessthan:
            return 4
        case .equals:
            return 4
        case .fin:
            return 1
        }
    }

    var defaultParamModes: [ParameterMode] {
        switch(self) {
        case .add:
            // params 1 & 2 position, param 3 (return value) = value
            return [.position,.position,.immediate]
        case .mul:
            // params 1 & 2 position, param 3 (return value) = value
            return [.position,.position,.immediate]
        case .input:
            // 1 parameter only.
            // Asks the user to provide an input, and the entered value
            // is stored at that location. For this we want to store the
            // position, *not* the placeholder value
            return [.immediate]
        case .output:
            // Prints the value to the user at the given position.
            return [.position]
        case .jumpiftrue:
            return [.position, .position]
        case .jumpiffalse:
            return [.position, .position]
        case .lessthan:
            return [.position, .position, .immediate]
        case .equals:
            return [.position, .position, .immediate]
        default:
            return []
        }
    }

    func execute(_ vals:[Int], idx:Int, userinput:(()->String)? = nil) -> (result:Int,storein:Int,idx:Int) {
        let newidx = idx + self.nvalues
        switch(self) {
            case .err:
                return (result:-1, storein: -1, idx: newidx)
            case .add:
                return (result: vals[0] + vals[1], storein: vals[2], idx: newidx);
            case .mul:
                return (result: vals[0] * vals[1], storein: vals[2], idx: newidx);
            case .input:
                print("Please provide program input: ")
                guard let fn = userinput else {
                    print("Fatal error: You need to tell me how to get input")
                    exit(EXIT_FAILURE)
                }
                let input = Int(fn())!
                print("Thanks, you gave me \(input)")
                return (result: input, storein: vals[0], idx: newidx)
            case .output:
                print("Output: \(vals[0])")
                return (result: vals[0], storein: -1, idx: newidx)
            case .jumpiftrue:
                return (result: 0, storein: -1, idx: vals[0] == 0 ? newidx : vals[1])
            case .jumpiffalse:
                return (result: 0, storein: -1, idx: vals[0] == 0 ? vals[1] : newidx)
            case .lessthan:
                let result = vals[0] < vals[1] ? 1 : 0
                return (result: result, storein: vals[2], idx: newidx)
            case .equals:
                let result = vals[0] == vals[1] ? 1 : 0
                return (result: result, storein: vals[2], idx: newidx)
            case .fin:
                return (result:-1, storein: -1, idx: newidx)
        }

    }
}

func Run(program:inout [Int], userinput: (()->String)? = nil) {
    var idx = 0
    repeat {
        // To get individual digits from an int we need to convert to base10
        // Which is basically what String is doing... in a way. Might not be as quick.
        let paramop = String.init(format: "%d", program[idx])
        // var tcode: OpCode?

        guard let code = OpCode(rawValue: Int(String(paramop.suffix(2)))!) else {
            print("Unknown opcode specified: \(program[idx]):\(paramop)")
            break
        }

        if(code == .fin) {
            break
        }

        var values: [Int] = []
        // Get the defaults in case only partially supplied in opcode
        var modes = code.defaultParamModes
        if(paramop.count > 2) {
            // parameter modes specified
            var specifiedModes = String(paramop.prefix(upTo: paramop.index(paramop.endIndex, offsetBy: -2)).reversed())
                                 .map {
                                     ParameterMode(rawValue: Int(String($0))!)
                                 }

            for (n,mode) in modes.enumerated() {
                if specifiedModes.count > n,
                    specifiedModes[n] != nil {
                    modes[n] = specifiedModes[n] ?? mode
                }
            }
        }

        // Get the values
        for (n,mode) in modes.enumerated() {
            let offset = 1+n

            switch(mode) {
            case .position:
                let pos = program[idx+offset]
                let val = program[pos]
                values.append(val)
            case .immediate:
                let val = program[idx+offset]
                values.append(val)
            }
        }

        let res = code.execute(values, idx: idx, userinput: userinput)
        if res.storein != -1 {
            program[res.storein] = res.result
        }
        idx = res.idx

        // idx += code.nvalues
    } while(idx < program.count)
}

// IntCode runner re-implemented. Use old tests to make sure no bugs.
func day2UnitTest() -> Bool {
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
    print("Day 2 Unit tests passed")
    return true
}

func day5UnitTest() -> Bool {
    let tests = [
        ([1002,4,3,4,33], [1002,4,3,4,99]),
        ([1101,100,-1,4,0], [1101,100,-1,4,99])
    ]

    for test in tests {
        var prog = test.0
        Run(program: &prog)
        guard prog == test.1 else {
            print("Unit tests failed")
            print("Expected: \(test.1)")
            print("Got \(prog)")
            return false
        }
    }
    print("Day 5 Unit tests passed")
    return true
}

func day5UnitTestPart2() -> Bool {
    let tests = [
        (prog: [3,9,8,9,10,9,4,9,99,-1,8], input: "8", expect: [3,9,8,9,10,9,4,9,99,1,8]),
        (prog: [3,9,8,9,10,9,4,9,99,-1,8], input: "7", expect: [3,9,8,9,10,9,4,9,99,0,8]),
        (prog: [3,9,7,9,10,9,4,9,99,-1,8], input: "7", expect: [3,9,7,9,10,9,4,9,99,1,8]),
        (prog: [3,9,7,9,10,9,4,9,99,-1,8], input: "8", expect: [3,9,7,9,10,9,4,9,99,0,8]),
        (prog: [3,3,1108,-1,8,3,4,3,99], input: "8", expect: [3,3,1108,1,8,3,4,3,99]),
        (prog: [3,3,1108,-1,8,3,4,3,99], input: "7", expect: [3,3,1108,0,8,3,4,3,99]),
        (prog: [3,3,1107,-1,8,3,4,3,99], input: "7", expect: [3,3,1107,1,8,3,4,3,99]),
        (prog: [3,3,1107,-1,8,3,4,3,99], input: "8", expect: [3,3,1107,0,8,3,4,3,99])
    ]
    for test in tests {
        var prog = test.prog
        Run(program: &prog) { return test.input }
        guard prog == test.expect else {
            print("Unit test failed")
            print("Expected \(test.expect)")
            print("Got \(prog)")
            return false
        }
    }
    print("Day 5 Part 2 Unit tests passed")
    return true
}

/*
    Uncomment the below for visual tests for jumping. I can't be bothered writing something to take
    a redirected "output" to automate the test :D
 */
 
// var posjetest = [3,12,6,12,15,1,13,14,13,4,13,99,-1, 0, 1, 9]
// Run(program: &posjetest) { return "0" }
// posjetest = [3,12,6,12,15,1,13,14,13,4,13,99,-1, 0, 1, 9]
// Run(program: &posjetest) { return "1" }
// posjetest = [3,12,6,12,15,1,13,14,13,4,13,99,-1, 0, 1, 9]
// Run(program: &posjetest) { return "-4" }

// var imjetest = [3,3,1105,-1,9,1101,0,0,12,4,12,99,1]
// Run(program: &imjetest) { return "0" }
// imjetest = [3,3,1105,-1,9,1101,0,0,12,4,12,99,1]
// Run(program: &imjetest) { return "10" }

// var largertest = [3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,
// 1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,
// 999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99]
// Run(program: &largertest) { return "6" }
// largertest = [3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,
// 1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,
// 999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99]
// Run(program: &largertest) { return "8" }
// largertest = [3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,
// 1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,
// 999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99]
// Run(program: &largertest) { return "20" }

let day5program = [3,225,1,225,6,6,1100,1,238,225,104,0,101,14,135,224,101,-69,224,224,4,224,1002,223,8,223,101,3,224,224,1,224,223,223,102,90,169,224,1001,224,-4590,224,4,224,1002,223,8,223,1001,224,1,224,1,224,223,223,1102,90,45,224,1001,224,-4050,224,4,224,102,8,223,223,101,5,224,224,1,224,223,223,1001,144,32,224,101,-72,224,224,4,224,102,8,223,223,101,3,224,224,1,223,224,223,1102,36,93,225,1101,88,52,225,1002,102,38,224,101,-3534,224,224,4,224,102,8,223,223,101,4,224,224,1,223,224,223,1102,15,57,225,1102,55,49,225,1102,11,33,225,1101,56,40,225,1,131,105,224,101,-103,224,224,4,224,102,8,223,223,1001,224,2,224,1,224,223,223,1102,51,39,225,1101,45,90,225,2,173,139,224,101,-495,224,224,4,224,1002,223,8,223,1001,224,5,224,1,223,224,223,1101,68,86,224,1001,224,-154,224,4,224,102,8,223,223,1001,224,1,224,1,224,223,223,4,223,99,0,0,0,677,0,0,0,0,0,0,0,0,0,0,0,1105,0,99999,1105,227,247,1105,1,99999,1005,227,99999,1005,0,256,1105,1,99999,1106,227,99999,1106,0,265,1105,1,99999,1006,0,99999,1006,227,274,1105,1,99999,1105,1,280,1105,1,99999,1,225,225,225,1101,294,0,0,105,1,0,1105,1,99999,1106,0,300,1105,1,99999,1,225,225,225,1101,314,0,0,106,0,0,1105,1,99999,108,226,677,224,1002,223,2,223,1006,224,329,1001,223,1,223,1007,226,226,224,1002,223,2,223,1006,224,344,101,1,223,223,1008,226,226,224,102,2,223,223,1006,224,359,1001,223,1,223,107,226,677,224,1002,223,2,223,1005,224,374,101,1,223,223,1107,677,226,224,102,2,223,223,1006,224,389,101,1,223,223,108,677,677,224,102,2,223,223,1006,224,404,1001,223,1,223,1108,677,226,224,102,2,223,223,1005,224,419,101,1,223,223,1007,677,226,224,1002,223,2,223,1006,224,434,101,1,223,223,1107,226,226,224,1002,223,2,223,1006,224,449,101,1,223,223,8,677,226,224,102,2,223,223,1006,224,464,1001,223,1,223,1107,226,677,224,102,2,223,223,1005,224,479,1001,223,1,223,1007,677,677,224,102,2,223,223,1005,224,494,1001,223,1,223,1108,677,677,224,102,2,223,223,1006,224,509,101,1,223,223,1008,677,677,224,102,2,223,223,1005,224,524,1001,223,1,223,107,226,226,224,1002,223,2,223,1005,224,539,101,1,223,223,7,226,226,224,102,2,223,223,1005,224,554,101,1,223,223,1108,226,677,224,1002,223,2,223,1006,224,569,1001,223,1,223,107,677,677,224,102,2,223,223,1005,224,584,101,1,223,223,7,677,226,224,1002,223,2,223,1005,224,599,101,1,223,223,108,226,226,224,1002,223,2,223,1005,224,614,101,1,223,223,1008,677,226,224,1002,223,2,223,1005,224,629,1001,223,1,223,7,226,677,224,102,2,223,223,1005,224,644,101,1,223,223,8,677,677,224,102,2,223,223,1005,224,659,1001,223,1,223,8,226,677,224,102,2,223,223,1006,224,674,1001,223,1,223,4,223,99,226]

func part1() {
    var program = day5program
    print("Running part 1")
    Run(program: &program) { return "1" }
}

func part2() {
    var program = day5program
    print("Running part 2")
    Run(program: &program) { return "5" }
}

_ = day2UnitTest()
_ = day5UnitTest()
_ = day5UnitTestPart2()
part1()
part2()