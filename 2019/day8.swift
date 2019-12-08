import Foundation

extension Array where Element == [Int] {
    func countOccurences(of lookup:Int) -> Int {
        var count = 0
        self.forEach { row in
            row.forEach { value in
                if value == lookup {
                    count += 1
                }
            }
        }
        return count
    }
}

struct Image {
    typealias Layer = [[Int]]
    var layers:[Layer]

    init(from str:String, dimensions:(width:Int,height:Int)) {
        layers = []
        let intarray = str.map { Int(String($0))! }
        let ppl = dimensions.width * dimensions.height
        let lc = intarray.count / ppl

        for l in 0..<lc {
            var layer: Layer = []
            let layerbase = l * ppl
            for row in 0..<dimensions.height {
                let rowbase = layerbase + (row * dimensions.width)
                let rowend = rowbase + dimensions.width
                let r = intarray[rowbase..<rowend]
                layer.append(Array(r))
            }
            layers.append(layer)
        }
    }

    func decode() -> Layer {
        let width = layers[0][0].count
        let height = layers[0].count
        var layer: Layer = Layer.init(repeating: Array.init(repeating: 2, count: width), count: height)
        
        layers.forEach { z in
            for (row, rowdata) in z.enumerated() {
                for (col, colvalue) in rowdata.enumerated() {
                    if layer[row][col] == 2 {
                        layer[row][col] = colvalue
                    }
                }
            }
        }
        
        return layer
    }
}

let file = String(data: FileManager.default.contents(atPath: "day8input") ?? Data(), encoding: .utf8)!
let image = Image(from: file, dimensions:(width: 25, height: 6))

func part1() {
    var zcount: [Int] = []
    for l in image.layers {
        let count = l.countOccurences(of: 0)
        zcount.append(count)
    }
    let selection = zcount.firstIndex(of: zcount.min()!)!
    print("Selected layer \(selection)")
    let layer = image.layers[selection]

    let result = layer.countOccurences(of: 1) * layer.countOccurences(of: 2)

    print("Part 1 result = \(result)")
}

func part2() {
    let layer = image.decode()
    layer.forEach { r in
        print("|", terminator: "")
        r.forEach { val in
            let output = String(format: "\u{001b}[%dm \u{001b}[0m", val == 1 ? 47 : 40 )
            print(output, terminator: "")
        }
        print("|")
    }
}

part1()

// You'd be better off runnin this in a terminal, VSCode's output
// panel doesn't display ANSI color properly. No idea why.  I guess
// I need an extension to do it, but there are too many to search
// through!
part2()