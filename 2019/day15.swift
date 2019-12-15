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

let robot = [3,1033,1008,1033,1,1032,1005,1032,31,1008,1033,2,1032,1005,1032,58,1008,1033,3,1032,1005,1032,81,1008,1033,4,1032,1005,1032,104,99,1002,1034,1,1039,1002,1036,1,1041,1001,1035,-1,1040,1008,1038,0,1043,102,-1,1043,1032,1,1037,1032,1042,1106,0,124,1001,1034,0,1039,1002,1036,1,1041,1001,1035,1,1040,1008,1038,0,1043,1,1037,1038,1042,1106,0,124,1001,1034,-1,1039,1008,1036,0,1041,1001,1035,0,1040,102,1,1038,1043,1002,1037,1,1042,1106,0,124,1001,1034,1,1039,1008,1036,0,1041,102,1,1035,1040,1001,1038,0,1043,1002,1037,1,1042,1006,1039,217,1006,1040,217,1008,1039,40,1032,1005,1032,217,1008,1040,40,1032,1005,1032,217,1008,1039,5,1032,1006,1032,165,1008,1040,35,1032,1006,1032,165,1102,1,2,1044,1106,0,224,2,1041,1043,1032,1006,1032,179,1102,1,1,1044,1106,0,224,1,1041,1043,1032,1006,1032,217,1,1042,1043,1032,1001,1032,-1,1032,1002,1032,39,1032,1,1032,1039,1032,101,-1,1032,1032,101,252,1032,211,1007,0,38,1044,1106,0,224,1101,0,0,1044,1106,0,224,1006,1044,247,1001,1039,0,1034,1001,1040,0,1035,101,0,1041,1036,102,1,1043,1038,1002,1042,1,1037,4,1044,1106,0,0,4,26,16,55,25,8,4,99,2,21,20,20,56,26,97,81,12,2,4,9,32,7,49,54,5,18,81,16,7,88,4,23,30,66,17,31,27,29,34,26,81,62,27,81,41,84,12,53,90,79,37,22,45,27,17,39,76,1,55,58,44,20,18,57,57,20,76,47,20,44,88,26,43,36,79,12,68,30,19,71,27,21,18,75,18,9,56,29,15,84,8,74,93,1,35,91,39,32,86,9,97,54,4,22,59,13,61,31,19,97,26,82,35,73,23,77,71,59,26,76,78,73,34,85,67,26,1,66,91,79,26,95,5,75,99,29,14,23,26,8,66,97,55,21,25,49,17,99,71,37,62,21,45,46,13,29,30,24,31,63,99,12,12,63,10,64,2,76,3,8,37,94,33,12,47,65,35,65,60,12,88,8,10,49,36,12,14,4,43,82,19,16,51,52,20,17,43,18,33,49,19,93,49,29,86,10,31,92,90,44,26,97,8,63,70,81,28,17,80,23,22,79,56,33,67,61,91,37,4,83,77,16,6,8,33,66,92,46,8,34,23,81,3,93,14,23,72,20,91,16,62,79,7,27,81,10,11,44,65,24,66,77,31,12,53,15,50,84,24,70,29,62,50,5,3,88,13,52,85,42,4,15,39,82,65,18,15,58,37,71,10,13,90,98,29,59,52,3,22,13,59,91,29,23,79,1,7,24,80,79,37,31,77,17,11,64,10,9,8,74,97,6,74,35,73,44,68,29,97,3,45,73,30,28,80,9,48,73,76,7,3,77,83,8,12,41,62,44,10,21,27,74,32,95,73,4,47,71,6,67,17,57,10,67,5,25,74,18,24,57,7,61,66,4,51,14,7,44,29,79,74,11,6,49,75,32,3,98,89,63,5,15,5,74,78,37,7,77,3,13,47,9,33,76,22,47,6,72,12,35,75,39,25,87,83,37,19,91,25,45,22,30,54,83,74,22,71,19,3,3,85,74,37,95,26,67,46,10,12,96,44,50,32,90,3,28,56,24,43,4,1,65,5,9,50,22,44,88,9,48,59,21,24,54,11,35,53,28,7,82,32,24,17,45,88,34,72,95,17,9,39,29,4,55,66,95,22,62,15,71,11,39,51,37,86,49,20,10,63,31,66,59,15,55,93,3,11,28,54,30,41,20,92,7,3,12,54,49,14,33,56,89,21,26,67,20,93,7,64,3,31,60,23,51,36,30,57,20,14,28,88,4,6,69,33,65,98,35,96,80,49,25,68,78,97,30,63,35,73,89,32,64,69,10,68,96,19,89,71,41,32,31,30,90,5,71,20,53,36,51,23,87,19,25,15,34,15,48,19,25,33,14,50,64,11,96,19,34,14,44,33,29,40,16,50,90,22,34,44,17,64,63,18,86,57,29,44,22,98,16,41,20,99,34,14,51,11,4,84,91,66,27,49,6,58,34,95,62,6,45,53,27,72,4,12,40,43,17,41,93,27,30,70,31,47,87,26,64,9,63,59,73,9,11,97,35,56,73,23,58,9,49,13,88,1,87,13,54,21,94,13,69,16,39,2,10,64,13,10,19,96,2,23,1,60,99,47,12,61,37,13,70,24,48,91,7,33,51,10,25,88,33,69,29,98,16,16,60,5,29,44,17,21,41,62,65,8,61,84,27,42,78,72,23,98,16,76,98,77,37,19,49,37,93,83,97,1,63,9,63,27,66,34,74,87,58,3,90,4,48,51,67,32,66,9,56,9,44,1,67,24,49,29,58,20,70,32,73,27,82,0,0,21,21,1,10,1,0,0,0,0,0,0]

var w = winsize()
if ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) != 0 {
    // print("rows:", w.ws_row, "cols", w.ws_col)
    print("Cannot get terminal width settings.")
    exit(EXIT_FAILURE)
}

class Display {
    let esc = "\u{001b}"
    func clearDisplay() {
        print("\(esc)[2J")
    }
    func setCursor(on: Bool = false) {
        switch(on) {
            case false:
                print("\(esc)[?25l")
            case true:
                print("\(esc)[\(w.ws_row - 2)H\(esc)[?25h")
        }
    }
}

let display = Display()
defer {
    display.setCursor(on: true)
}
display.clearDisplay()
display.setCursor(on: false)

enum Color: Int {
    case white = 47, red = 41, black = 40
    func render() -> String {
        return String(format: "\u{001b}[%dm \u{001b}[0m", self.rawValue)
    }
}

enum Object {
    case empty, wall, oxygen, robot

    func render() -> String {
        switch(self) {
            case .empty:
                let object = Color.white
                return object.render()
            case .wall:
                let object = Color.red
                return object.render()
            case .oxygen:
                return "🛠"
            case .robot:
                return "o"
        }
    }
}

struct Point: Equatable, Hashable {
    var x = 0
    var y = 0
    
    func draw(object: Object) {
        print("\(display.esc)[\(y);\(x)H\(object.render())")
    }

    func getPossibleChildren() -> [Point] {
        var children: [Point] = []
        children.append(Point(x: x-1, y: y))
        children.append(Point(x: x+1, y: y))
        children.append(Point(x: x, y: y-1))
        children.append(Point(x: x, y: y+1))
        return children
    }

    func getDirection(to point: Point) -> Int {
        if x == point.x {
            // Remember on terminal y axis is inverted
            if y < point.y {
                return 2
            } else {
                return 1
            }
        }
        if y == point.y {
            if x < point.x {
                return 4
            } else {
                return 3
            }
        }
        // We shouldn't ever get here. An unknown code
        // will cause the IntCode program to exit
        print("Exiting dude. \(self)->\(point)")
        return 0
    }
}

// Uncomment the below if you want to use interactive movement mode
// from the keyboard. This enables RAW mode so you can hit arrow keys
// without having to press enter for getc() call to return
//
// var settings:termios = termios()
// tcgetattr(STDIN_FILENO, &settings )
// var newsettings = settings
// // Restore terminal settings when we quit
// defer {
//     tcsetattr(STDIN_FILENO, TCSAFLUSH, &settings)
// }
// newsettings.c_lflag &= ~UInt(ECHO | ICANON)
// tcsetattr(STDIN_FILENO, TCSAFLUSH, &newsettings)

var startpoint = Point(x: Int(w.ws_col/2), y: Int(w.ws_row/2) )
var currentpoint = startpoint
var targetpoint = currentpoint
func getManualInput() -> Int {
    let directions: [Int32:Int] = [65: 1, 66: 2, 68: 3, 67: 4]
    var c: Int32 = 0
    repeat {
        c = getchar()
        if c == 27 {
            c = getchar()
            if c == 91 {
                c = getchar()
            }
        }
        if c == 10 {
            exit(EXIT_SUCCESS)
        }
    } while !directions.contains { $0.key == c }
    let direction = directions[c]!
    switch(direction) {
        case 1:
            targetpoint.y -= 1
        case 2:
            targetpoint.y += 1
        case 3:
            targetpoint.x -= 1
        case 4:
            targetpoint.x += 1
        default:
            print("This won't happen.")
    }
    return direction
}

func interactiveoutputhandler(value: Int) -> Void {
    switch(value) {
        case 0:
            targetpoint.draw(object: Object.wall)
            targetpoint = currentpoint
        case 1:
            currentpoint.draw(object: Object.empty)
            currentpoint = targetpoint
        case 2:
            targetpoint.draw(object: Object.oxygen)
            // print("Found oxygen at \(targetpoint)")
        default:
            print("This won't happen")
    }
    currentpoint.draw(object: Object.robot)
}

var stack: [(Point,[Point])] = []
var deadends: [Point] = []
var visited: [Point] = []
var corridorspaces = Set<Point>()
func addtostack(from point:Point) -> Bool {
    guard visited.contains(point) == false else {
        // We've already evaluated this path. Prevent loops.
        return false
    }
    visited.append(point)
    var children = point.getPossibleChildren()
    children.removeAll { newtarget in
        newtarget == point
        || deadends.contains(newtarget)
        || stack.contains { target, targets in
                target == newtarget
            }
    }
    stack.append((point,children))
    return true
}
func getnextfromstack() -> Point? {
    guard stack.count > 0 else {
        return nil
    }
    if stack[stack.endIndex-1].1.count == 0 {
        let location = stack.removeLast().0
        deadends.append(location)
        // Return back to the previous stack entry starting point
        guard stack.count > 0 else {
            return nil
        }
        return stack[stack.endIndex-1].0
    }
    return stack[stack.endIndex-1].1[0]
}
func popfromstack() {
    guard stack.count > 0,
        stack[stack.endIndex-1].1.count > 0 else { return }
    _ = stack[stack.endIndex-1].1.removeFirst()
}

addtostack(from: currentpoint)

var foundoxygen = false
var oxygenpoint: Point?
func generatedoutputhandler(value: Int) -> Void {
    var isoxygen = false
    switch(value) {
        case 0:
            targetpoint.draw(object: Object.wall)
            popfromstack()
        case 1:
            if currentpoint != oxygenpoint {
                currentpoint.draw(object: Object.empty)
            } else {
                currentpoint.draw(object: Object.oxygen)
            }

            if !addtostack(from: targetpoint) {
                popfromstack()
            }

            currentpoint = targetpoint
            corridorspaces.insert(targetpoint)
        case 2:
            targetpoint.draw(object: Object.oxygen)
            // Comment out this if statement to run part1
            if !addtostack(from: targetpoint) {
                popfromstack()
            }
            currentpoint = targetpoint
            isoxygen = true
            oxygenpoint = targetpoint
            corridorspaces.insert(targetpoint)
            // Uncomment this line to run part 1 instead of part2
            // foundoxygen = true
            // print("Found oxygen at \(targetpoint)")
        default:
            print("This won't happen")
    }
    if !isoxygen {
        currentpoint.draw(object: Object.robot)
    }
}

// Only four movement commands are understood:
//     north (1), south (2), west (3), and east (4)
func generateInput() -> Int {
    if foundoxygen {
        print("Found oxygen")
        return 0
    }

    repeat {
        if let t = getnextfromstack() {
            targetpoint = t
        } else {
            print("We've fully explored the map")
            print("There are \(corridorspaces.count) corridor spaces")
            return 0
        }
    } while(targetpoint == currentpoint)

    return currentpoint.getDirection(to: targetpoint)
}

var program = load(program: robot, memsize: 2048)
Run(program: &program, output: generatedoutputhandler(value:), userinput: generateInput  )

if foundoxygen {
    print("Optimal moves to find oxygen machine = \(stack.count)")
} else {
    // Iterate through the possible corridorspaces, removing all adjacent
    // spaces simultaneously until the list is empty. The number of iterations
    // = the number of minutes required to fill the corridors with oxygen.
    var spaces = corridorspaces
    if let start = corridorspaces.firstIndex(of: oxygenpoint!) {
        print("Got our starting point ... good")
        var count = 0
        var locations = corridorspaces[start].getPossibleChildren().filter {
            spaces.contains($0)
        }
        repeat {
            count += 1
            var newlocations: [Point] = []
            locations.forEach {
                spaces.remove($0)
                newlocations.append(contentsOf: $0.getPossibleChildren())
            }
            
            locations = newlocations.filter { spaces.contains($0) }
        } while(spaces.count > 0)
        print("It took \(count) minutes to fill with oxygen")
    } else {
        print("Well this didn't go well ....")
    }
}