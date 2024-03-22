//: [Previous](@previous)

import Foundation

//let input = """
//0 3 6 9 12 15
//1 3 6 10 15 21
//10 13 16 21 30 45
//""".split(separator: "\n").map { $0.split(separator: " ").compactMap { Int($0) } }

let input = Utils.loadLines(file: "puzzleinput")!.map { $0.split(separator: " ").compactMap { Int($0) } }

extension Array where Element == Int {
    func getDiffs() -> [Int]? {
        var diffs: [Int] = []
        var last: Int?
        self.forEach {
            if let a = last {
                diffs.append($0 - a)
            }
            last = $0
        }
        if let _ = diffs.first(where: {$0 != 0}) {
            return diffs
        }
        return nil
    }
    
    func extrapolatePreviousValue() -> Int {
        var matrix = [self]
        var done = false
        repeat {
            if let diffs = matrix.last?.getDiffs() {
                matrix.append(diffs)
            } else {
                done = true
            }
        } while done == false

        repeat {
            let a = matrix.removeLast()
            var b = matrix.removeLast()
            b.insert(b.first! - a.first!, at: 0)
//            b.append(b.last! + a.last!)
            matrix.append(b)
        } while matrix.count > 1
        
        return matrix.last!.first!
    }
    
    func extrapolateNextValue() -> Int {
        var matrix = [self]
        var done = false
        repeat {
            if let diffs = matrix.last?.getDiffs() {
                matrix.append(diffs)
            } else {
                done = true
            }
        } while done == false

        repeat {
            let a = matrix.removeLast()
            var b = matrix.removeLast()
            b.append(b.last! + a.last!)
            matrix.append(b)
        } while matrix.count > 1
        
        return matrix.last!.last!
    }
}

let answerone = input.reduce(0, { res, part in
    res + part.extrapolateNextValue()
})

print("Part 1:", answerone)

let answertwo = input.reduce(0, { res, part in
    res + part.extrapolatePreviousValue()
})

print("Part 2:", answertwo)


//: [Next](@next)
