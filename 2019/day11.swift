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

enum Direction: Int{
    case left = 0, up = 1, right = 2, down = 3
    mutating func turn(in direction: Direction) {
        switch(direction) {
            case .left:
                if self == .left {
                    self = .down
                    return
                }
                self = Direction(rawValue: self.rawValue - 1)!
            case .right:
                if self == .down {
                    self = .left
                    return
                }
                self = Direction(rawValue: self.rawValue + 1)!
            default:
                print("Invalid direction")
                exit(EXIT_FAILURE)
        }
    }
}

struct Point: Hashable {
    var x = 0
    var y = 0

    mutating func move(count: Int, in direction: Direction) {
        switch(direction) {
            case .left:
                self.x -= count
            case .up:
                self.y += count
            case .right:
                self.x += count
            case .down:
                self.y -= count
        }
    }
}

func load(program: [Int], memsize:Int) -> [Int] {
    var memory = Array(repeating: 0, count: 1024*memsize/MemoryLayout<Int>.size)
    memory.insert(contentsOf: program, at: 0)
    return memory
}

let program = [3,8,1005,8,337,1106,0,11,0,0,0,104,1,104,0,3,8,1002,8,-1,10,101,1,10,10,4,10,108,1,8,10,4,10,1002,8,1,28,2,1,15,10,2,2,10,10,1,1107,0,10,2,1105,18,10,3,8,102,-1,8,10,1001,10,1,10,4,10,1008,8,1,10,4,10,101,0,8,67,1,1003,4,10,2,1007,14,10,1006,0,64,3,8,102,-1,8,10,1001,10,1,10,4,10,1008,8,0,10,4,10,102,1,8,100,2,102,15,10,3,8,1002,8,-1,10,1001,10,1,10,4,10,108,0,8,10,4,10,1001,8,0,125,2,1003,7,10,1006,0,10,2,1007,13,10,2,103,14,10,3,8,102,-1,8,10,1001,10,1,10,4,10,1008,8,1,10,4,10,101,0,8,163,1006,0,5,3,8,1002,8,-1,10,1001,10,1,10,4,10,1008,8,0,10,4,10,102,1,8,188,1,1101,2,10,1006,0,82,3,8,1002,8,-1,10,101,1,10,10,4,10,1008,8,0,10,4,10,101,0,8,217,1,1109,1,10,1,109,9,10,1,1009,9,10,1006,0,41,3,8,102,-1,8,10,1001,10,1,10,4,10,1008,8,1,10,4,10,102,1,8,254,2,104,1,10,2,8,15,10,3,8,1002,8,-1,10,1001,10,1,10,4,10,1008,8,1,10,4,10,101,0,8,284,1,1107,11,10,3,8,102,-1,8,10,101,1,10,10,4,10,108,0,8,10,4,10,101,0,8,309,2,1001,10,10,1006,0,49,101,1,9,9,1007,9,1058,10,1005,10,15,99,109,659,104,0,104,1,21101,937267929896,0,1,21101,0,354,0,1106,0,458,21102,1,936995566336,1,21102,1,365,0,1106,0,458,3,10,104,0,104,1,3,10,104,0,104,0,3,10,104,0,104,1,3,10,104,0,104,1,3,10,104,0,104,0,3,10,104,0,104,1,21101,3263269979,0,1,21101,0,412,0,1106,0,458,21102,1,46174071899,1,21101,0,423,0,1106,0,458,3,10,104,0,104,0,3,10,104,0,104,0,21101,825544561428,0,1,21102,446,1,0,1105,1,458,21102,1,867966018404,1,21101,457,0,0,1106,0,458,99,109,2,21202,-1,1,1,21102,40,1,2,21101,489,0,3,21102,1,479,0,1105,1,522,109,-2,2106,0,0,0,1,0,0,1,109,2,3,10,204,-1,1001,484,485,500,4,0,1001,484,1,484,108,4,484,10,1006,10,516,1102,0,1,484,109,-2,2105,1,0,0,109,4,2102,1,-1,521,1207,-3,0,10,1006,10,539,21101,0,0,-3,21201,-3,0,1,22101,0,-2,2,21101,1,0,3,21102,558,1,0,1105,1,563,109,-4,2105,1,0,109,5,1207,-3,1,10,1006,10,586,2207,-4,-2,10,1006,10,586,22102,1,-4,-4,1106,0,654,22101,0,-4,1,21201,-3,-1,2,21202,-2,2,3,21102,1,605,0,1105,1,563,22101,0,1,-4,21102,1,1,-1,2207,-4,-2,10,1006,10,624,21102,1,0,-1,22202,-2,-1,-2,2107,0,-3,10,1006,10,646,21201,-1,0,1,21102,646,1,0,106,0,521,21202,-2,-1,-2,22201,-4,-2,-4,109,-5,2106,0,0]


func runProgram(startingOnWhite:Bool = false) {
    // We're on a map of unkown size. Let's just test a 150x150 array and see if we
    // hit an OOB error, increase if necessary
    var size = 500
    if startingOnWhite {
        // Truncate the output a bit to make the ascii colour output easier to read
        size = 110
    }
    var map = Array(repeating: Array(repeating: 0, count: size), count: size)
    // Swift's Set automatically does collision detection for us (Y)
    var paintedPoints = Set<Point>()
    // Robot will either paint or move, no need for anything other than a bool here
    var shouldPaint = true
    var location = Point(x: map.count/2, y: map.count/2)
    if startingOnWhite {
        map[location.x][location.y] = 1
    }
    var heading = Direction.up
    // var 
    var memory = load(program: program, memsize: 1024)
    Run(program: &memory, output: { command in 
        if shouldPaint {
            // command = colour we should paint
            map[location.x][location.y] = command
            // store the location we just painted. As it's a set
            // it automatically handles duplicates.
            paintedPoints.insert(location)
        } else {
            // command = direction we should move
            let direction: Direction = command == 1 ? .right : .left
            heading.turn(in: direction)
            location.move(count: 1, in: heading)
        }
        shouldPaint.toggle()
    }, userinput: {
        return map[location.x][location.y]
    })

    if startingOnWhite {
        map.forEach { row in
            for val in row {
                let output = String(format: "\u{001b}[%dm \u{001b}[0m", val == 1 ? 47 : 40)
                print(output, terminator: "")
            }
            print("")
        }
    } else {
        print("Count = \(paintedPoints.count)")
    }
}

runProgram()

runProgram(startingOnWhite: true)