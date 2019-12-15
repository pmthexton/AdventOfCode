import Foundation

struct Chemical: Hashable {
    var name: String
    var count: Int
    
    init(name: String, count:Int) {
        self.name = name
        self.count = count
    }
}

var reactions: [Chemical: [Chemical]] = [:]

extension Dictionary where Key == Chemical, Value == [Chemical] {
    func getRequired(for element:Chemical) -> [Chemical] {
        var val: [Chemical] = []

        self.forEach {
            if $0.key.name == element.name {
                var multiplier = element.count/$0.key.count
                let remainder = element.count % $0.key.count
                if remainder > 0 {
                    multiplier += 1
                    // print("We needed MORE \($0.key.name) \(multiplier)")
                }
                // print("We needed \(remainder) more \(element.name)")

                // print("Calculated multiplier from \(element.count),\($0.key.count) = \(multiplier)")
                $0.value.forEach {
                    val.append(Chemical(name: $0.name, count: $0.count * multiplier))
                }
            }
        }
        // print("For \(element), need \(val)")
        return val
    }

    func getSpec(for element:String) -> (key: Chemical, value: [Chemical])? {
        for el in self {
            if el.key.name == element {
                return el
            }
        }
        return nil
    }

    func getRequired(for element:String) -> [Chemical] {
        return getRequired(for: Chemical(name: element, count: 1))
    }

    // Get the numbers of each type of thing that are required.
    // Then I can loop through the full list to find what actually directly
    // needs ORE to account for re-use of spares etc.ß
    func getRequiredComponents(for element:String) -> [String:Int] {
        var result: [String:Int] = [:]
        var a = getRequired(for: element)
        var b: [Chemical] = []
        repeat {
            // print("A is now \(a)")
            b.removeAll()
            a.forEach {
                if $0.name != "ORE" {                   
                    // print("\tFinding requirements for \($0)")
                    if result[$0.name] == nil {
                        result[$0.name] = 0
                    }
                    result[$0.name]! += $0.count
                    b.append(contentsOf: getRequired(for: Chemical(name: $0.name, count: $0.count)))
                }
            }
            a = b
        } while(!b.isEmpty)
        return result
    }
}

class Factory {
    var inventory: [String:Int] = [:]

    func getOreFor(_ count:Int, element:String) -> Int {
        let required = reactions.getSpec(for: element)!
        var create = count
        
        if let currentstock = inventory[element] {

            if currentstock >= create {
                // print("We've got more than enough \(element) already! We wanted \(create) and we have \(currentstock)")
                inventory[element] = currentstock - create
                return 0
            }
            // print("We're not fully stocked, but we've got partial \(currentstock) for \(element) .. we want \(create)")
            create -= currentstock
            inventory.removeValue(forKey: element)
        }

        var multiplier = [1,create/required.key.count].max()!
        if create > required.key.count && create % required.key.count > 0 {
            multiplier += 1
        }

        let overstock = (required.key.count * multiplier)-create
        if overstock > 0 {
            // print("Adding \(overstock) \(element) to inventory")
            if let currentstock = inventory[element] {
                inventory[element] = overstock + currentstock
            } else {
                inventory[element] = overstock
            }
        }
        
        let oreused = required.value.reduce(0) { (ore, component) in
            var result = ore
            if component.name == "ORE" {
                // print("\(element).. count \(count), \(multiplier), \(component.count * multiplier)")
                result += component.count * multiplier
            } else {
                // print("for \(element) need to find ore usage for \(component.count) \(component.name) * \(multiplier)")
                result += getOreFor(component.count * multiplier, element: component.name)
            }
            return result
        }

        return oreused
    }
}
let data = """
4 BFNQL => 9 LMCRF
2 XGWNS, 7 TCRNC => 5 TPZCH
4 RKHMQ, 1 QHRG, 5 JDSNJ => 4 XGWNS
6 HWTBC, 4 XGWNS => 6 CWCD
1 BKPZH, 2 FLZX => 9 HWFQG
1 GDVD, 2 HTSW => 8 CNQW
2 RMDG => 9 RKHMQ
3 RTLHZ => 3 MSKWT
1 QLNHG, 1 RJHCP => 3 GRDJ
10 DLSD, 2 SWKHJ, 15 HTSW => 1 TCRNC
4 SWKHJ, 24 ZHDSD, 2 DLSD => 3 CPGJ
1 SWKHJ => 1 THJHK
129 ORE => 8 KLSMQ
3 SLNKW, 4 RTLHZ => 4 LPVGC
1 SLNKW => 5 RLGFX
2 QHRG, 1 SGMK => 8 RJHCP
9 RGKCF, 7 QHRG => 6 ZHDSD
8 XGWNS, 1 CPGJ => 2 QLNHG
2 MQFJF, 7 TBVH, 7 FZXS => 2 WZMRW
13 ZHDSD, 11 SLNKW, 18 RJHCP => 2 CZJR
1 CNQW, 5 GRDJ, 3 GDVD => 4 FLZX
129 ORE => 4 RHSHR
2 HWTBC, 2 JDSNJ => 8 QPBHG
1 BKPZH, 8 SWKHJ => 6 WSWBV
8 RJHCP, 7 FRGJK => 1 GSDT
6 QPBHG => 4 BKPZH
17 PCRQV, 6 BFNQL, 9 GSDT, 10 MQDHX, 1 ZHDSD, 1 GRDJ, 14 BRGXB, 3 RTLHZ => 8 CFGK
8 RMDG => 6 SGMK
3 CZJR => 8 RTLHZ
3 BFRTV => 7 RGKCF
6 FRGJK, 8 CZJR, 4 GRDJ => 4 BRGXB
4 VRVGB => 7 PCRQV
4 TCRNC, 1 TBVH, 2 FZXS, 1 BQGM, 1 THJHK, 19 RLGFX => 2 CRJTJ
5 RDNJK => 6 SWKHJ
2 FLVC, 2 SLNKW, 30 HWTBC => 8 DLSD
6 TBVH, 3 ZHDSD => 5 BQGM
17 RLGFX => 4 SCZQN
8 SWKHJ => 6 FZXS
9 LZHZ => 3 QDCL
2 ZHDSD => 1 RDNJK
15 FZXS, 3 TPZCH => 6 MQFJF
12 RLGFX, 9 QPBHG, 6 HTSW => 1 BFNQL
150 ORE => 9 BFRTV
2 BFRTV, 2 KLSMQ => 2 RMDG
4 VFLNM, 30 RKHMQ, 4 CRJTJ, 24 CFGK, 21 SCZQN, 4 BMGBG, 9 HWFQG, 34 CWCD, 7 LPVGC, 10 QDCL, 2 WSWBV, 2 WTZX => 1 FUEL
6 RHSHR, 3 RGKCF, 1 QHRG => 6 JDSNJ
3 MQDHX, 2 XGWNS, 12 GRDJ => 9 LZHZ
128 ORE => 6 ZBWLC
9 JDSNJ, 7 RMDG => 8 FLVC
4 DLSD, 12 CZJR, 3 MSKWT => 4 MQDHX
2 BXNX, 4 ZBWLC => 3 QHRG
19 LMCRF, 3 JDSNJ => 2 BMGBG
1 RJHCP, 26 SGMK => 9 HTSW
2 QPBHG => 8 VFLNM
2 RGKCF => 9 SLNKW
3 LZHZ, 2 GRDJ => 2 TBVH
100 ORE => 2 BXNX
4 DLSD, 21 JDSNJ => 8 GDVD
2 QHRG => 2 HWTBC
1 LPVGC, 8 XGWNS => 8 FRGJK
9 FZXS => 7 VRVGB
7 WZMRW, 1 TBVH, 1 VFLNM, 8 CNQW, 15 LZHZ, 25 PCRQV, 2 BRGXB => 4 WTZX
"""


for reaction in data.components(separatedBy: "\n") {
    var isoutput = false
    var countval = 0
    var inputs: [Chemical] = []

    for part in reaction.components(separatedBy: CharacterSet(charactersIn: " ,")).filter({!$0.isEmpty}) {
        if part == "=>" {
            isoutput = true
            continue
        }
        if let i = Int(part) {
            countval = i
        } else {
            if isoutput {
                reactions[Chemical(name: part, count: countval)] = inputs
            } else {
                inputs.append(Chemical(name: part, count: countval))
            }
        }
    }
}


let part1 = Factory()
let part1answer = part1.getOreFor(1, element: "FUEL")
print("Ore required for 1 fuel = \(part1answer)")

//
// Part 2. Find maximum amount of fuel that can be made from a given amount of ore.
// Just binary chop it. It'll be quick enough.
let ore = 1000000000000
var firstguess = ore / part1answer
var cont = true
var ints = [0,ore]
while(cont) {
    let part2 = Factory()
    let middle = Int(
        floor(
            Double(
                ints[0]+ints[1]
                )/2))
    print("First guess = \(middle)")
    var testanswer = part2.getOreFor(middle, element: "FUEL")
    print("Test answer = \(testanswer))")
    if testanswer > ore {
        ints[1] = middle
    } else if testanswer < ore {
        ints[0] = middle
    } else {
        print("This was unlikely. Exact answer? \(middle)")
    }

    if(ints[1] - ints[0]) <= 1 {
        cont = false
    }
}
print("Exited loop with min/max values \(ints)")
var answers = ints.map { ($0, Factory().getOreFor($0, element: "FUEL")) }
answers.forEach {
    print($0.0,"->",$0.1,$0.1 <= ore ? "Correct" : "Incorrect")
}
