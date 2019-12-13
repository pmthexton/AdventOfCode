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

func load(program: [Int], memsize:Int) -> [Int] {
    var memory = Array(repeating: 0, count: 1024*memsize/MemoryLayout<Int>.size)
    memory.insert(contentsOf: program, at: 0)
    return memory
}

let game = [1,380,379,385,1008,2399,203850,381,1005,381,12,99,109,2400,1101,0,0,383,1102,1,0,382,20101,0,382,1,21001,383,0,2,21101,37,0,0,1105,1,578,4,382,4,383,204,1,1001,382,1,382,1007,382,44,381,1005,381,22,1001,383,1,383,1007,383,20,381,1005,381,18,1006,385,69,99,104,-1,104,0,4,386,3,384,1007,384,0,381,1005,381,94,107,0,384,381,1005,381,108,1105,1,161,107,1,392,381,1006,381,161,1102,1,-1,384,1105,1,119,1007,392,42,381,1006,381,161,1102,1,1,384,20101,0,392,1,21101,18,0,2,21102,1,0,3,21101,138,0,0,1105,1,549,1,392,384,392,21001,392,0,1,21101,18,0,2,21102,1,3,3,21102,161,1,0,1105,1,549,1101,0,0,384,20001,388,390,1,21001,389,0,2,21102,1,180,0,1106,0,578,1206,1,213,1208,1,2,381,1006,381,205,20001,388,390,1,20101,0,389,2,21102,205,1,0,1105,1,393,1002,390,-1,390,1101,0,1,384,21002,388,1,1,20001,389,391,2,21101,0,228,0,1105,1,578,1206,1,261,1208,1,2,381,1006,381,253,21001,388,0,1,20001,389,391,2,21102,1,253,0,1106,0,393,1002,391,-1,391,1101,0,1,384,1005,384,161,20001,388,390,1,20001,389,391,2,21102,279,1,0,1105,1,578,1206,1,316,1208,1,2,381,1006,381,304,20001,388,390,1,20001,389,391,2,21102,1,304,0,1106,0,393,1002,390,-1,390,1002,391,-1,391,1102,1,1,384,1005,384,161,20101,0,388,1,21002,389,1,2,21101,0,0,3,21101,338,0,0,1106,0,549,1,388,390,388,1,389,391,389,21001,388,0,1,20101,0,389,2,21102,4,1,3,21101,0,365,0,1106,0,549,1007,389,19,381,1005,381,75,104,-1,104,0,104,0,99,0,1,0,0,0,0,0,0,341,20,15,1,1,22,109,3,22101,0,-2,1,22102,1,-1,2,21101,0,0,3,21102,1,414,0,1105,1,549,22102,1,-2,1,22102,1,-1,2,21102,429,1,0,1106,0,601,1202,1,1,435,1,386,0,386,104,-1,104,0,4,386,1001,387,-1,387,1005,387,451,99,109,-3,2106,0,0,109,8,22202,-7,-6,-3,22201,-3,-5,-3,21202,-4,64,-2,2207,-3,-2,381,1005,381,492,21202,-2,-1,-1,22201,-3,-1,-3,2207,-3,-2,381,1006,381,481,21202,-4,8,-2,2207,-3,-2,381,1005,381,518,21202,-2,-1,-1,22201,-3,-1,-3,2207,-3,-2,381,1006,381,507,2207,-3,-4,381,1005,381,540,21202,-4,-1,-1,22201,-3,-1,-3,2207,-3,-4,381,1006,381,529,21202,-3,1,-7,109,-8,2105,1,0,109,4,1202,-2,44,566,201,-3,566,566,101,639,566,566,1201,-1,0,0,204,-3,204,-2,204,-1,109,-4,2106,0,0,109,3,1202,-1,44,594,201,-2,594,594,101,639,594,594,20101,0,0,-2,109,-3,2106,0,0,109,3,22102,20,-2,1,22201,1,-1,1,21101,0,443,2,21102,1,526,3,21102,880,1,4,21102,1,630,0,1105,1,456,21201,1,1519,-2,109,-3,2106,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,2,2,2,2,0,0,2,2,0,2,0,0,2,2,2,2,0,2,2,2,2,0,2,0,2,0,2,0,2,0,2,0,2,0,2,0,2,0,0,2,0,1,1,0,2,0,0,2,0,2,2,2,0,2,0,2,2,2,2,2,2,0,2,2,2,2,2,2,2,0,2,0,2,0,0,0,2,2,0,0,2,2,2,2,0,1,1,0,2,2,2,2,2,2,2,2,0,2,2,2,2,2,2,0,2,2,2,2,0,0,0,2,2,0,2,2,2,2,2,2,0,0,2,2,2,2,2,2,0,1,1,0,2,0,2,2,2,2,2,0,0,2,0,0,2,0,2,2,2,2,2,2,2,0,2,0,0,2,0,2,2,2,0,2,2,2,2,2,2,2,2,2,0,1,1,0,2,2,2,0,2,0,0,2,2,0,2,2,2,0,2,0,2,2,2,2,2,0,0,0,2,0,0,2,2,2,0,2,2,0,0,0,2,2,2,0,0,1,1,0,2,2,2,2,2,2,2,0,0,2,2,2,2,0,0,2,2,2,0,2,2,2,0,2,2,2,2,0,2,0,2,2,0,2,2,2,0,2,0,2,0,1,1,0,2,2,2,2,0,2,0,2,2,2,2,2,2,2,2,0,0,0,2,2,2,0,2,0,2,0,2,2,2,2,0,2,2,0,2,0,2,0,2,0,0,1,1,0,2,2,2,2,0,2,2,0,2,2,0,0,0,2,0,2,2,2,2,0,2,0,0,0,2,2,0,2,2,2,2,0,0,2,2,2,2,0,2,2,0,1,1,0,2,2,2,0,2,2,0,2,2,2,2,2,2,2,2,2,2,2,0,2,0,0,2,2,2,2,0,2,2,2,0,2,2,2,2,2,2,0,2,2,0,1,1,0,2,2,2,2,2,0,2,2,2,0,2,2,0,0,2,2,2,0,2,2,2,2,2,2,0,2,0,2,2,0,0,2,2,0,2,2,2,0,2,2,0,1,1,0,2,2,2,2,2,0,2,2,2,0,2,2,2,2,2,0,2,0,2,2,2,0,2,0,0,2,0,2,2,2,2,2,2,2,0,2,2,2,2,2,0,1,1,0,0,2,2,2,2,2,2,0,2,2,2,2,2,2,2,0,2,0,2,2,2,2,2,2,2,2,0,2,0,0,2,2,0,2,0,2,2,2,2,2,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,11,38,49,70,10,39,91,58,63,68,52,75,23,63,39,47,35,75,29,29,52,19,47,94,19,66,22,88,37,37,78,74,50,60,79,90,76,65,62,46,70,10,5,78,40,26,89,43,42,11,26,57,77,13,3,28,60,91,71,34,83,69,11,40,97,12,59,2,35,50,62,24,93,66,1,29,31,31,70,97,37,72,39,55,83,60,6,81,2,6,49,73,44,59,88,14,13,76,25,30,85,82,12,12,20,34,11,87,11,95,16,28,84,79,10,96,48,55,62,38,1,7,65,7,63,5,30,52,48,77,31,39,87,20,70,4,91,56,48,20,90,21,89,90,27,37,20,72,89,82,93,84,30,53,85,86,16,7,1,14,2,61,75,25,57,53,89,8,36,29,22,66,21,97,55,19,65,29,55,98,40,48,84,32,87,53,98,98,63,14,29,42,63,90,30,53,58,45,31,2,16,78,84,26,86,59,68,70,42,2,45,90,62,32,62,9,68,14,27,89,97,11,96,60,6,43,29,56,2,80,52,76,92,44,66,62,13,95,7,84,81,47,7,69,33,35,33,65,7,83,15,92,49,18,31,91,40,96,44,64,56,77,31,6,16,68,13,77,32,76,29,23,92,75,32,86,45,94,88,26,79,17,29,70,14,91,9,9,71,79,1,25,72,5,16,62,3,92,8,58,30,9,11,21,7,13,26,11,65,17,83,43,94,78,10,72,96,53,53,61,53,31,73,36,12,66,65,88,81,97,54,82,60,18,81,77,46,31,68,67,55,85,63,42,43,44,71,37,31,94,63,41,61,26,9,16,78,85,54,8,62,86,91,58,42,14,85,25,62,75,55,60,1,94,84,49,67,70,96,16,97,40,5,80,83,58,24,7,42,27,33,97,97,95,94,8,44,18,64,96,80,80,14,16,27,43,26,52,32,41,6,44,83,53,89,11,50,43,64,46,9,97,21,38,59,70,89,18,98,17,69,95,44,70,35,73,22,94,4,78,11,74,15,72,87,84,85,75,34,17,65,11,96,86,39,69,55,59,56,58,97,39,54,70,71,25,15,97,29,66,78,54,54,82,92,28,28,60,98,8,18,5,30,4,3,15,65,4,89,76,27,90,36,47,75,70,82,95,44,13,63,56,36,43,92,66,61,85,73,71,60,51,56,90,44,40,73,15,76,67,51,36,44,12,58,45,17,80,97,30,57,47,96,3,95,2,27,77,84,13,69,89,78,8,45,58,22,74,84,12,10,32,16,20,4,21,98,52,55,77,24,14,38,76,82,73,39,5,19,51,75,89,31,51,60,95,89,2,15,39,17,17,77,79,60,21,21,87,81,1,95,5,5,59,3,93,3,34,51,56,11,39,29,34,56,65,36,20,16,44,28,11,44,15,59,95,30,24,33,24,64,4,6,96,62,72,40,93,30,42,45,81,49,82,77,58,9,18,60,86,53,90,57,69,26,86,67,97,90,79,77,64,19,27,13,10,89,92,33,1,23,97,72,19,11,25,89,87,65,54,93,78,34,49,36,82,61,59,76,9,97,39,32,26,54,62,62,3,33,75,29,87,6,30,92,14,23,33,58,95,92,52,12,95,70,18,64,11,81,76,47,85,40,52,51,65,91,18,30,63,59,63,66,39,76,87,63,98,65,67,17,72,63,9,73,74,12,79,35,48,17,68,40,50,13,46,75,61,53,50,26,37,44,92,46,6,42,17,85,56,85,75,90,63,73,61,74,5,18,70,39,75,67,6,16,10,36,80,28,69,37,42,39,19,40,9,4,49,8,97,82,2,44,86,86,95,49,40,26,86,71,45,11,61,9,98,82,67,88,47,54,86,89,97,6,31,59,9,81,24,76,59,95,19,40,63,9,90,83,10,45,96,80,57,16,8,97,64,36,28,37,88,64,47,19,51,92,30,15,55,2,7,73,22,2,8,82,69,39,63,48,43,27,23,40,82,57,19,42,36,92,57,66,54,8,48,94,76,70,76,203850]

enum Color: Int {
    case white = 47, red = 41
    func render() -> String {
        return String(format: "\u{001b}[%dm \u{001b}[0m", self.rawValue)
    }
}

enum Object: Int {
    case empty = 0, wall = 1, block = 2, paddle = 3, ball = 4

    func render() -> String {
        switch(self) {
            case .empty:
                return " "
            case .wall:
                let cell = Color.white
                return cell.render()
            case .block:
                let cell = Color.red
                return cell.render()
            case .paddle:
                return "-"
            case .ball:
                return "o"
        }
    }
}

// Cheat. Just track the ball direction.
struct Point {
    var x = 0
    var y = 0
}

var x: [Int] = []
var y: [Int] = []

class Tile {
    var x = 0
    var y = 0
    var object = Object(rawValue: 0)

    init(input: [Int]) {
        x = input[0]
        y = input[1]
        object = Object(rawValue: input[2])
    }

    func draw() {
        if let object = object {
        print("\(Display.esc)[\(y);\(x)H\(object.render())")
        } else {
            print("Woaaaah what the hell? \(self.x),\(self.y)")
            exit(EXIT_FAILURE)
        }
    }
}

class Display {
    static let esc = "\u{001b}"
    static func clearDisplay() {
        print("\(esc)[2J")
    }
    static func setCursor(on: Bool = false) {
        switch(on) {
            case false:
                print("\(esc)[?25l")
            case true:
                print("\(esc)[\(y.max()!+10)H\(esc)[?25h")
        }
    }
}

Display.clearDisplay()
Display.setCursor(on: false)

var outputbuffer: [Int] = []
var countblocks = 0
var score = 0
var scorelocation = 0
var hasinput = false
var ball = Point()
var paddle = Point()

func outputhandler(value: Int) -> Void {
    outputbuffer.append(value)
    if outputbuffer.count == 3 {
        if !hasinput {
        x.append(outputbuffer[0])
        y.append(outputbuffer[1])
        }
        if outputbuffer[0] == -1 && outputbuffer[1] == 0 {
            score = outputbuffer[2]
            print("\(Display.esc)[\(y.max()!+4);0HScore: \(score)")
            outputbuffer.removeAll()
            return
        }
        let tile = Tile(input: outputbuffer)
        if tile.object == .block {
            countblocks += 1
        }
        if tile.object == .paddle {
            paddle = Point(x: outputbuffer[0], y: outputbuffer[1])
        }
        if tile.object == .ball {
            ball = Point(x: outputbuffer[0], y: outputbuffer[1])
        }
        // moves.append(tile)
        tile.draw()
        outputbuffer.removeAll()
    }
}

func getInput() -> Int {
    if ball.x > paddle.x {
    return 1
    }
    if ball.x < paddle.x {
        return -1
    }
    return 0
}

var memory = load(program: game, memsize: 2048)
memory[0]=2
Run(program: &memory, output: outputhandler, userinput: getInput)
Display.setCursor(on: true)

// Comment out setting memory[0] above, and uncomment the line
// below to run part 1
// print("There are \(countblocks) block tiles on screen")