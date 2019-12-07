import Foundation
import Dispatch

func getPossibleThrusterCombinations(current: [Int], set combinations:inout [[Int]]) {
    let signals = [0,1,2,3,4]
    if current.count == signals.count {
        combinations.append(current)
        return
    }
    var interim = current
    for i in 0..<signals.count {
        if !interim.contains(i) {
            interim.append(i)
            getPossibleThrusterCombinations(current: interim, set: &combinations)
            _ = interim.popLast()
        }
    }
}

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

    func execute(_ vals:[Int], idx:Int, userinput:(()->Int)? = nil) -> (result:Int,storein:Int,idx:Int) {
        let newidx = idx + self.nvalues
        switch(self) {
            case .err:
                return (result:-1, storein: -1, idx: newidx)
            case .add:
                return (result: vals[0] + vals[1], storein: vals[2], idx: newidx);
            case .mul:
                return (result: vals[0] * vals[1], storein: vals[2], idx: newidx);
            case .input:
                guard let fn = userinput else {
                    print("Fatal error: You need to tell me how to get input")
                    exit(EXIT_FAILURE)
                }
                let input = fn()
                return (result: input, storein: vals[0], idx: newidx)
            case .output:
                return (result: vals[0], storein: -2, idx: newidx)
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

func Run(program:inout [Int], output:inout Int, userinput: (()->Int)? = nil) {
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
            let specifiedModes = String(paramop.prefix(upTo: paramop.index(paramop.endIndex, offsetBy: -2)).reversed())
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
        if res.storein == -2 {
            output = res.result
        }
        if res.storein >= 0 {
            program[res.storein] = res.result
        }
        
        idx = res.idx

        // idx += code.nvalues
    } while(idx < program.count)
}

class Thruster {
    var inputs = [0,0]
    var output = 0
    
    init(phase: Int) {
        self.inputs[0] = phase
    }

    func run(program:[Int], ret: (Int)->Void) {
        var p = program
        var idx = 0
        Run(program: &p, output: &output) { let res = self.inputs[idx]; idx += 1; return res }
        ret(output)
    }
}

extension Array where Element:Thruster {
    @_semantics("array.init")
    init(phases:[Int]) {
        self = phases.map(Thruster.init(phase:)) as! Array<Element>
    }

    func run(program:[Int]) -> Int {
        var finalval = -1
        for (n,thruster) in self.enumerated() {
            thruster.run(program:program) { output in 
                if n < self.count-1 {
                    self[n+1].inputs[1] = output
                } else {
                    finalval = output
                }
            }
        }
        return finalval
    }
}

func p1unitTests() -> Bool {
    let tests = [
        (prog: [3,15,3,16,1002,16,10,16,1,16,15,15,4,15,99,0,0], phases: [4,3,2,1,0], expect: 43210),
        (prog: [3,23,3,24,1002,24,10,24,1002,23,-1,23,101,5,23,23,1,24,23,23,4,23,99,0,0], phases: [0,1,2,3,4], expect: 54321),
        (prog: [3,31,3,32,1002,32,10,32,1001,31,-2,31,1007,31,0,33,1002,33,7,33,1,33,31,31,1,32,31,31,4,31,99,0,0,0], phases: [1,0,4,3,2], expect: 65210)
    ]
    for test in tests {
        let thrusters = Array<Thruster>(phases: test.phases)
        guard thrusters.run(program: test.prog) == test.expect else {
            print("Unit test expecting value \(test.expect) from phases \(test.phases) failed")
            return false
        }
    }
    print("p1unitTests passed")
    return true
}

func part1() {
    // This is a long line, I cba reading from a file
    let program = [3,8,1001,8,10,8,105,1,0,0,21,30,55,76,97,114,195,276,357,438,99999,3,9,102,3,9,9,4,9,99,3,9,1002,9,3,9,1001,9,5,9,1002,9,2,9,1001,9,2,9,102,2,9,9,4,9,99,3,9,1002,9,5,9,1001,9,2,9,102,5,9,9,1001,9,4,9,4,9,99,3,9,1001,9,4,9,102,5,9,9,101,4,9,9,1002,9,4,9,4,9,99,3,9,101,2,9,9,102,4,9,9,1001,9,5,9,4,9,99,3,9,1002,9,2,9,4,9,3,9,102,2,9,9,4,9,3,9,102,2,9,9,4,9,3,9,1001,9,1,9,4,9,3,9,102,2,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,102,2,9,9,4,9,3,9,102,2,9,9,4,9,3,9,1001,9,2,9,4,9,3,9,101,1,9,9,4,9,99,3,9,1002,9,2,9,4,9,3,9,1001,9,2,9,4,9,3,9,101,1,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,1001,9,2,9,4,9,3,9,1001,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,1001,9,2,9,4,9,3,9,101,2,9,9,4,9,3,9,102,2,9,9,4,9,99,3,9,101,1,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,1001,9,1,9,4,9,3,9,1002,9,2,9,4,9,3,9,1001,9,1,9,4,9,3,9,1001,9,1,9,4,9,3,9,101,1,9,9,4,9,3,9,102,2,9,9,4,9,3,9,1001,9,1,9,4,9,3,9,1001,9,1,9,4,9,99,3,9,1001,9,1,9,4,9,3,9,1002,9,2,9,4,9,3,9,1001,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,1001,9,1,9,4,9,3,9,101,2,9,9,4,9,3,9,102,2,9,9,4,9,3,9,101,2,9,9,4,9,3,9,101,1,9,9,4,9,3,9,1001,9,1,9,4,9,99,3,9,101,2,9,9,4,9,3,9,102,2,9,9,4,9,3,9,101,2,9,9,4,9,3,9,101,1,9,9,4,9,3,9,101,2,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,102,2,9,9,4,9,3,9,1001,9,1,9,4,9,3,9,1001,9,1,9,4,9,3,9,101,2,9,9,4,9,99]
    var combinations: [[Int]] = []
    getPossibleThrusterCombinations(current: [], set: &combinations)
    var results: [Int] = []
    for combination in combinations {
        let thrusters = Array<Thruster>(phases: combination)
        results.append(thrusters.run(program: program))
        print("Completed combination \(combination)")
    }
    print("Highest signal to thrusters = \(results.max()!)")
}

guard p1unitTests() else {
    print("Unit tests failed")
    exit(EXIT_FAILURE)
}

part1()