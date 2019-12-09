import Foundation

enum ParameterMode: Int {
    case position = 0, immediate = 1, relative = 2
}

enum ParameterPurpose {
    case input, output
}

enum OpCode: Int {
    case err = -1,
    add = 1, mul = 2, input = 3,
    output = 4, jumpiftrue = 5,
    jumpiffalse = 6, lessthan = 7,
    equals = 8, adjust = 9, fin = 99
    
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
        case .adjust:
            return 2
        case .fin:
            return 1
        }
    }
    
    var paramPurpose: [ParameterPurpose] {
        switch(self) {
        case .add:
            // params 1 & 2 position, param 3 (return value) = value
            return [.input,.input,.output]
        case .mul:
            // params 1 & 2 position, param 3 (return value) = value
            return [.input,.input,.output]
        case .input:
            // 1 parameter only.
            // Asks the user to provide an input, and the entered value
            // is stored at that location. For this we want to store the
            // position, *not* the placeholder value
            return [.output]
        case .output:
            // Prints the value to the user at the given position.
            return [.input]
        case .jumpiftrue:
            return [.input, .input]
        case .jumpiffalse:
            return [.input, .input]
        case .lessthan:
            return [.input, .input, .output]
        case .equals:
            return [.input, .input, .output]
        case .adjust:
            return [.input]
        default:
            return []
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
        case .adjust:
            return [.position]
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
        case .adjust:
            return (result: vals[0], storein: -3, idx: newidx)
        case .fin:
            return (result:-1, storein: -1, idx: newidx)
        }
        
    }
}

func Run(program:inout [Int], output:(Int)->Void, userinput: (()->Int)? = nil) {
    var idx = 0
    var relbase = 0
    repeat {
        // To get individual digits from an int we need to convert to base10
        // Which is basically what String is doing... in a way. Might not be as quick.
        let paramop = String.init(format: "%d", program[idx])
        
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
            case .relative:
                // Hack. If the op code would write, we need to store the relative
                // *position*, NOT the actual retrieved value
                // For now, we determine this by storing the position as an argument
                // if the "default" for a parameter would be .immediate
                let immediate = program[idx+offset]
                let pos = relbase + immediate
                if code.paramPurpose[n] == .output {
                    values.append(pos)
                } else {
                    let val = program[pos]
                    values.append(val)
                }
            }
        }

        let res = code.execute(values, idx: idx, userinput: userinput)

        if res.storein == -3 {
            relbase += res.result
        }
        if res.storein == -2 {
            output(res.result)
        }
        if res.storein >= 0 {
            program[res.storein] = res.result
        }

        idx = res.idx
        
        // idx += code.nvalues
    } while(idx < program.count)
}

func regressionTests() -> Bool {
    let tests = [
        ([1,9,10,3,2,3,11,0,99,30,40,50], [3500,9,10,70,2,3,11,0,99,30,40,50]),
        ([1,0,0,0,99],[2,0,0,0,99]),
        ([2,3,0,3,99],[2,3,0,6,99]),
        ([2,4,4,5,99,0],[2,4,4,5,99,9801]),
        ([1,1,1,4,99,5,6,0,99],[30,1,1,4,2,5,6,0,99]),
        ([1002,4,3,4,33], [1002,4,3,4,99]),
        ([1101,100,-1,4,0], [1101,100,-1,4,99])
    ]
    
    for test in tests {
        var prog = test.0
        Run(program: &prog, output: {_ in })
        guard prog == test.1 else {
            print("Regression test failed.")
            print("\(test.0) expected \(test.1), got \(prog)")
            return false
        }
    }
    print("regressionTests passed")
    return true
}

func load(program: [Int], memsize:Int) -> [Int] {
    var memory = Array(repeating: 0, count: 1024*memsize/MemoryLayout<Int>.size)
    memory.insert(contentsOf: program, at: 0)
    return memory
}

func unitTests() -> Bool {
    var storage: [Int] = []
    let tests = [
        (prog: [109,1,204,-1,1001,100,1,100,1008,100,16,101,1006,101,0,99],
         output: { value in
            storage.append(value)
        },
         validate: { prog in
            return prog == storage
        }
        ),
        (
            prog: [1102,34915192,34915192,7,4,7,99,0],
            output: { value in
                storage.append(value)
            },
            validate: {_ in
                // This is a brutal check. Just convert to string and count the digits that way
                let s = String(storage[0])
                return s.count == 16
            }
        ),
        (
            prog: [104,1125899906842624,99],
            output: { value in
                storage.append(value)
            },
            validate: { _ in
                return storage[0] == 1125899906842624 
            }
        )
    ]
    for test in tests {
        var prog = load(program: test.prog, memsize: 32)
        storage = []
        Run(program: &prog, output: test.output)
        guard test.validate(test.prog) else {
            print("Unit test failed \(test)")
            exit(EXIT_FAILURE)
        }
    }
    print("unitTests passed")
    return true
}

// _ = regressionTests()
_ = unitTests()

let p = [1102,34463338,34463338,63,1007,63,34463338,63,1005,63,53,1101,0,3,1000,109,988,209,12,9,1000,209,6,209,3,203,0,1008,1000,1,63,1005,63,65,1008,1000,2,63,1005,63,902,1008,1000,0,63,1005,63,58,4,25,104,0,99,4,0,104,0,99,4,17,104,0,99,0,0,1102,32,1,1019,1101,0,500,1023,1101,0,636,1025,1102,36,1,1010,1101,0,29,1013,1102,864,1,1029,1102,21,1,1000,1102,1,507,1022,1102,1,28,1011,1102,38,1,1008,1101,0,35,1004,1101,25,0,1018,1102,24,1,1005,1102,30,1,1009,1102,1,869,1028,1101,0,37,1007,1102,1,23,1017,1102,1,20,1015,1102,1,22,1003,1101,0,39,1001,1102,1,31,1012,1101,701,0,1026,1101,0,641,1024,1101,0,34,1016,1102,1,0,1020,1102,698,1,1027,1102,33,1,1002,1102,26,1,1006,1101,0,1,1021,1101,0,27,1014,109,12,21101,40,0,0,1008,1012,40,63,1005,63,203,4,187,1105,1,207,1001,64,1,64,1002,64,2,64,109,-11,1207,7,37,63,1005,63,223,1105,1,229,4,213,1001,64,1,64,1002,64,2,64,109,14,1206,5,247,4,235,1001,64,1,64,1105,1,247,1002,64,2,64,109,-2,1207,-4,31,63,1005,63,269,4,253,1001,64,1,64,1105,1,269,1002,64,2,64,109,-6,1208,-5,35,63,1005,63,289,1001,64,1,64,1106,0,291,4,275,1002,64,2,64,109,9,21108,41,39,-1,1005,1015,311,1001,64,1,64,1105,1,313,4,297,1002,64,2,64,109,-5,2101,0,-9,63,1008,63,33,63,1005,63,339,4,319,1001,64,1,64,1106,0,339,1002,64,2,64,1205,10,351,4,343,1106,0,355,1001,64,1,64,1002,64,2,64,109,-18,2108,35,9,63,1005,63,375,1001,64,1,64,1105,1,377,4,361,1002,64,2,64,109,18,1205,9,389,1105,1,395,4,383,1001,64,1,64,1002,64,2,64,109,7,21107,42,41,-8,1005,1010,415,1001,64,1,64,1106,0,417,4,401,1002,64,2,64,109,-12,2102,1,0,63,1008,63,29,63,1005,63,437,1106,0,443,4,423,1001,64,1,64,1002,64,2,64,109,3,1208,0,30,63,1005,63,461,4,449,1105,1,465,1001,64,1,64,1002,64,2,64,109,5,1202,-5,1,63,1008,63,31,63,1005,63,489,1001,64,1,64,1106,0,491,4,471,1002,64,2,64,109,15,2105,1,-6,1001,64,1,64,1106,0,509,4,497,1002,64,2,64,109,-10,1206,2,525,1001,64,1,64,1106,0,527,4,515,1002,64,2,64,109,-18,1202,0,1,63,1008,63,39,63,1005,63,553,4,533,1001,64,1,64,1106,0,553,1002,64,2,64,109,1,2107,21,1,63,1005,63,571,4,559,1105,1,575,1001,64,1,64,1002,64,2,64,109,7,2102,1,-8,63,1008,63,39,63,1005,63,601,4,581,1001,64,1,64,1105,1,601,1002,64,2,64,109,2,1201,-7,0,63,1008,63,35,63,1005,63,623,4,607,1106,0,627,1001,64,1,64,1002,64,2,64,109,20,2105,1,-7,4,633,1106,0,645,1001,64,1,64,1002,64,2,64,109,-16,21107,43,44,-4,1005,1011,663,4,651,1105,1,667,1001,64,1,64,1002,64,2,64,109,-11,2107,36,0,63,1005,63,687,1001,64,1,64,1106,0,689,4,673,1002,64,2,64,109,19,2106,0,4,1106,0,707,4,695,1001,64,1,64,1002,64,2,64,109,-14,21108,44,44,6,1005,1015,725,4,713,1105,1,729,1001,64,1,64,1002,64,2,64,109,1,1201,-6,0,63,1008,63,36,63,1005,63,749,1106,0,755,4,735,1001,64,1,64,1002,64,2,64,109,-1,21101,45,0,10,1008,1019,42,63,1005,63,775,1105,1,781,4,761,1001,64,1,64,1002,64,2,64,109,16,21102,46,1,-7,1008,1018,44,63,1005,63,801,1105,1,807,4,787,1001,64,1,64,1002,64,2,64,109,-3,21102,47,1,-4,1008,1018,47,63,1005,63,833,4,813,1001,64,1,64,1105,1,833,1002,64,2,64,109,-14,2108,38,0,63,1005,63,851,4,839,1105,1,855,1001,64,1,64,1002,64,2,64,109,17,2106,0,3,4,861,1106,0,873,1001,64,1,64,1002,64,2,64,109,-31,2101,0,10,63,1008,63,36,63,1005,63,897,1001,64,1,64,1106,0,899,4,879,4,64,99,21101,0,27,1,21101,0,913,0,1106,0,920,21201,1,53612,1,204,1,99,109,3,1207,-2,3,63,1005,63,962,21201,-2,-1,1,21102,940,1,0,1106,0,920,21202,1,1,-1,21201,-2,-3,1,21101,955,0,0,1106,0,920,22201,1,-1,-2,1105,1,966,21201,-2,0,-2,109,-3,2106,0,0]
var prog = load(program: p, memsize: 1024)
Run(program: &prog, output: {value in
    print("o: \(value)")
}) { print("Asked for input..."); return 2 }
