import Foundation
import Combine

let file = String(data: FileManager.default.contents(atPath: "day7input") ?? Data(), encoding: .utf8)!

enum Gate: String {
    case AND = "AND", OR = "OR", LSHIFT = "LSHIFT", RSHIFT = "RSHIFT", NOT = "NOT"
    var inputs: Int {
        switch(self) {
        case .AND:
            return 2
        case .OR:
            return 2
        case .LSHIFT:
            return 2
        case .RSHIFT:
            return 2
        case .NOT:
            return 1
        }
    }
    func getOutput(inputs:[UInt16]) -> UInt16? {
        switch(self) {
        case .AND:
            return inputs[0] & inputs[1]
        case .OR:
            return inputs[0] | inputs[1]
        case .LSHIFT:
            return inputs[0] << inputs[1]
        case .RSHIFT:
            return inputs[0] >> inputs[1]
        case .NOT:
            return ~inputs[0]
        }
    }
}

class Input {
    var value: UInt16?
    private let publisher = CurrentValueSubject<UInt16?, Never>(nil)
    func subscribe() -> AnyPublisher<UInt16?,Never> {
        // Create the publisher, and then send our data (if we already have it)
        // so that anything we're being connected to can immediately get the value
        // using a common sink method
        return publisher.eraseToAnyPublisher()
    }
    func set(value:UInt16) {
        if self.value != value {
            self.value = value
            publisher.send(value)
        }
    }
    init(value:UInt16? = nil) {
        self.value = value
        if let v = self.value {
            publisher.send(v)
        }
    }
}

class Wire {
    var input: Input
    init(input: Input) {
        self.input = input
    }
    func subscribe() -> AnyPublisher<UInt16?,Never> {
        return input.subscribe()
    }
}

class LogicGate {
    var inputs: [Input]
    var output: Input
    let gate: Gate
    private var disposables = Set<AnyCancellable>()
    private var signalledValues = 0
    init(gate: Gate, inputs: [Input]) {
        self.gate = gate
        self.inputs = inputs
        self.output = Input()
        for input in self.inputs {
            input.subscribe().sink { value in
                if value != nil {
                    self.signalledValues += 1
                    if self.signalledValues >= gate.inputs {
                        let newvalue = gate.getOutput(inputs: inputs.map() { $0.value! })!
                        if newvalue != self.output.value {
                            self.output.set(value: newvalue)
                        }
                    }
                }
            }.store(in: &disposables)
        }
    }
    
    func subscribe() -> AnyPublisher<UInt16?, Never> {
        return output.subscribe()
    }
}

let testprogram = """
123 -> x
456 -> y
x AND y -> d
x OR y -> e
x LSHIFT 2 -> f
y RSHIFT 2 -> g
NOT x -> h
NOT y -> i
"""

var disposables = Set<AnyCancellable>()
var gates: [LogicGate] = []
var wires: [String: Wire] = [:]

extension Array where Element == LogicGate {
    mutating func add(connecting gate:Gate, with inputs:[Input], and wire:Wire) {
        let lg = LogicGate(gate: gate, inputs: inputs)
        lg.subscribe().sink { v in 
            if let value = v {
                wire.input.set(value: value)
            }
        }.store(in: &disposables)
        self.append(lg)
    }
}

extension Dictionary where Key == String, Value == Wire {
    mutating func add(label: String, connected to:Input?) {
        var wire = self[label]
        if wire == nil {
            wire = Wire(input: Input())
            self[label] = wire
        }
        if let input = to {
            input.subscribe().sink { v in 
                if let value = v {
                    wire!.input.set(value: value)
                }
            }.store(in: &disposables)
        }
    }
}

for line in file.components(separatedBy: "\n") {
    var inputs: [Input] = []
    var gate:Gate?
    var connect = false

    let tokens = line.components(separatedBy: " ")
    // The final token on each line is always a wire.
    // This is a nice place to ensure we know about said
    // wire already when plumbing in it's inputs
    if wires[tokens.last!] == nil {
        wires[tokens.last!] = Wire(input: Input())
    }
    for token in line.components(separatedBy: " ") {
        if connect {
            if let gate = gate {
                gates.add(connecting: gate, with: inputs, and: wires[token]!)
            } else if inputs.count == 1 {
                wires.add(label: token, connected: inputs[0])
            }
            continue
        }
        if let i = UInt16(token) {
            inputs.append(Input(value: i))
            continue
        }
        if let g = Gate(rawValue: token) {
            gate = g
            continue
        }
        if token == "->" {
            connect = true
            continue
        }
        if wires[token] == nil {
            // New wire definition we've not seen before.
            // Create a wire with an unset value.
            // We store the wire for later reference, and store
            // the input (which for a wire is just a value) for
            // passing in to the correct destination
            let i = Input()
            inputs.append(i)
            wires[token] = Wire(input: i)
        } else {
            // We're referencing a wire's value, store in the input
            // array for connection
            inputs.append(wires[token]!.input)
        }
    }
}

// wires.sorted() { $0.0 < $1.0 }.forEach { k, v in
//     if let _ = v.input.value {
//         print(k,":",v.input.value!)}
//     // } else {
//     //     print(k,": nil")
//     // }
// }

print("Running Part 1")
print("Part 1: A wire value: ", wires["a"]!.input.value!)
print("Running Part 2")
wires["b"]!.input.set(value: wires["a"]!.input.value!)
print("Part 2: A wire value: ", wires["a"]!.input.value!)