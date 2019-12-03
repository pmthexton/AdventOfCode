import Cocoa
import Foundation

struct Point: Equatable, Comparable {
    static func < (lhs: Point, rhs: Point) -> Bool {
        return lhs.manhattan < rhs.manhattan
    }

    var x = 0
    var y = 0

    var manhattan: Int {
        return abs(x) + abs(y)
    }
}

extension Point {
    func distance(to point:Point) -> Int {
        var distance = 0
        if(point.x == x) {
            distance = point.y - y
        }
        if(point.y == y) {
            distance = point.x - x
        }
        return abs(distance)
    }
}

struct Line {
    var p1: Point
    var p2: Point
    var distance: Int

    init(p1: Point, p2: Point, distance: Int) {
        self.p1 = p1
        self.p2 = p2
        self.distance = distance
        self.minx = [self.p1.x,self.p2.x].min()!
        self.maxx = [self.p1.x,self.p2.x].max()!
        self.miny = [self.p1.y,self.p2.y].min()!
        self.maxy = [self.p1.y,self.p2.y].max()!
    }

    var minx: Int
    var maxx: Int
    var miny: Int
    var maxy: Int
}

extension Line {
    // find intersection of straight lines.
    // I like life without angled grid lines.
    func intersect(of other: Line) -> Point? {
        var result:Point?
        if p1.x == p2.x,
            other.p1.y == other.p2.y,
            stride(from: miny, to: maxy, by: 1).contains(other.p1.y),
            stride(from: other.minx, to: other.maxx, by: 1).contains(p1.x)
         {
            result = Point(x: p1.x, y: other.p1.y)
        }
        if p1.y == p2.y,
            other.p1.x == other.p2.x,
            stride(from: minx, to: maxx, by: 1).contains(other.p1.x),
            stride(from: other.miny, to: other.maxy, by: 1).contains(p1.y)
        {
            result = Point(x: other.p1.x, y: p1.y)
        }

        return result
    }
}

extension Line {
    func contains(point:Point) -> Bool {

        return point.x >= minx
            && point.x <= maxx
            && point.y >= miny
            && point.y <= maxy
    }
}

struct Wire {
    var lines:[Line]
}

extension Wire {
    init (input:String) {
        lines = []
        var x=0
        var y=0
        var distance=0

        let instructions = input.components(separatedBy: ",")

        for var inst in instructions {
            var newx = x
            var newy = y
            let direction = inst.removeFirst()
            let count = Int(inst)!
            distance += count
            switch(direction) {
            case "L":
                newx = x-count
            case "R":
                newx = x+count
            case "D":
                newy = y-count
            case "U":
                newy = y+count
            default:
                print("Something weird happened")
            }
            lines.append(Line(p1: Point(x: x, y: y),
                                   p2: Point(x: newx, y: newy),
                                   distance: distance))
            x = newx
            y = newy
        }
    }

    func intersect(of other: Wire) -> [Point] {
        var intersections: [Point] = []
        for line in lines {
            for otherline in other.lines {
                if let point = line.intersect(of: otherline),
                point.x != 0,
                point.y != 0 {
                    intersections.append(point)
                }
            }
        }
        return intersections
    }
}

extension Wire {
    func distance(to point:Point) -> Int {
        var distance = 0
        for line in lines {
            if line.contains(point: point) {
                distance += line.p1.distance(to: point)
                break
            } else {
                distance = line.distance
            }
        }

        return distance
    }

    func shortestDistance(to wire:Wire) -> Int {
        var distances: [Int] = []
        let intersections = intersect(of: wire)
        for intersection in intersections {
            distances.append(distance(to: intersection) + wire.distance(to: intersection))
        }
        return distances.min()!
    }
}

func part1UnitTests() -> Bool {
    let tests = [
        ("""
R8,U5,L5,D3
U7,R6,D4,L4
""", 6),
        ("""
R75,D30,R83,U83,L12,D49,R71,U7,L72
U62,R66,U55,R34,D71,R55,D58,R83
""", 159),
        ("""
R98,U47,R26,D63,R33,U87,L62,D20,R33,U53,R51
U98,R91,D20,R16,D67,R40,U7,R15,U6,R7
""", 135)
    ]

    for test in tests {
        let lines = test.0.components(separatedBy: "\n")
        guard lines.count == 2 else {
            print("Unexpected test data")
            exit(EXIT_FAILURE)
        }
        let line1 = Wire(input: lines[0])
        let line2 = Wire(input: lines[1])
        guard line1.intersect(of: line2).min()?.manhattan ?? 0 == test.1 else {
            print("Unit test failed")
            print(test.0)
            print(test.1)
            return false
        }
    }

    return true
}

func part2UnitTests() -> Bool {
    let tests = [
        ("""
R75,D30,R83,U83,L12,D49,R71,U7,L72
U62,R66,U55,R34,D71,R55,D58,R83
""", 610),
        ("""
R98,U47,R26,D63,R33,U87,L62,D20,R33,U53,R51
U98,R91,D20,R16,D67,R40,U7,R15,U6,R7
""", 410)
    ]

    for test in tests {
        let lines = test.0.components(separatedBy: "\n")
        guard lines.count == 2 else {
            print("Unexpected test data")
            exit(EXIT_FAILURE)
        }
        let line1=Wire(input: lines[0])
        let line2=Wire(input: lines[1])
        if line1.shortestDistance(to: line2) != test.1 {
            print("Unit test failed result \(test.1)")
            print("Got result \(line1.shortestDistance(to: line2))")
            return false
        }
        print("Unit test passed result \(test.1)")
    }

    return true
}

let inputdata = """
R990,D362,L316,U101,R352,U798,L314,D564,R961,D634,L203,U601,R973,U227,R996,D639,L868,D135,L977,D201,R911,D486,R906,U719,L546,U324,R302,D200,L879,D206,L872,U681,R628,D272,R511,D827,L929,U915,L399,U696,R412,D640,R234,U487,R789,U354,L620,D914,L7,D228,L55,D591,L250,D228,R816,U935,R553,U98,L833,D418,R582,D793,R804,U283,R859,D206,L842,U663,L935,U495,L995,D181,R75,D33,R126,U489,L894,D675,R33,U239,L623,D931,L830,U63,R77,D576,L85,D415,R443,U603,R654,U495,L273,U583,R10,D648,L840,U904,R489,D655,R997,U559,L614,U917,R809,U540,L41,U519,R256,U111,R29,D603,L931,U518,R443,D51,L788,U483,L665,U890,L392,D701,R907,D125,L438,D107,L266,U766,R743,D343,R898,U293,L318,U417,L23,U44,L668,U614,R83,U31,R452,U823,R16,D418,R68,U823,L53,D638,L394,D714,R992,U196,R913,D526,L458,U428,L412,U901,R610,U348,L904,D815,R274,U439,R207,D81,L20,D507,L179,U249,L221,U603,L897,U490,R127,U99,L709,U925,L818,D777,R292,U935,R801,U331,R412,U759,L698,D53,L969,U492,L502,D137,R513,D999,L808,D618,L240,U378,L284,D726,L609,U530,R537,D36,L504,D26,R244,D692,L186,U767,L690,U182,R559,D926,R706,D132,L325,D846,R494,U238,L519,U655,R57,U658,L471,D717,L964,D346,L448,U286,L457,D504,R614,U652,R583,D780,R882,U417,R573,D297,L144,U347,L254,D589,L387,U309,L88,D510,R435,U636,L640,U801,R774,U678,R247,D846,L775,U527,L225,U798,R577,U897,R11,U153,L297,D748,L284,U806,R512,U906,L181,U39,R264,D47,L561,D441,L181,U210,L278,U998,R256,D278,R350,U466,L335,D310,L4,U298,L531,D423,R851,U285,L235,D139,R209,U882,R801,D36,L777,D153,L63
L995,D598,R577,U346,L797,D375,R621,D709,R781,U55,R965,U327,L479,U148,L334,U93,R644,U632,L557,D136,L690,D548,R982,D703,L971,U399,R600,D785,L504,U984,R18,U190,L755,D737,L787,D921,R303,U513,L544,U954,L814,U239,R550,D458,R518,D538,R362,D350,L103,U17,L362,D480,L80,U639,L361,D75,L356,D849,R635,U633,R934,U351,L314,U960,R657,U802,L687,U385,L558,D984,L996,U765,L147,D366,R908,U981,R44,U336,R396,U85,R819,D582,L21,D920,L627,D103,R922,U195,L412,D385,L159,U446,L152,U400,L303,U549,R734,D709,R661,U430,R177,U857,L53,U555,R35,D919,L163,D630,L162,U259,R46,D89,R965,D410,R37,U39,R621,D606,L816,D659,L668,D418,L775,D911,R296,U488,L129,U869,L455,U663,L942,U813,L274,D677,R161,D338,R455,D580,R976,D984,L336,U742,R334,U130,L210,U523,R958,U177,R126,U469,L513,D14,L772,D423,L369,D661,R167,D449,L685,U871,L930,U630,L54,D581,L921,U839,R782,D844,L581,D995,R110,U365,L594,D595,R391,D298,R297,U469,L148,D34,R5,D609,L654,U172,R940,D858,L682,D92,R395,D683,R947,U311,L850,U151,R452,U641,L599,D640,R86,U584,L518,D597,L724,D282,L691,D957,L119,U30,L8,D514,R237,U599,R775,U413,R802,D132,R925,U133,L980,D981,R272,U632,R995,U427,R770,D722,L817,D609,R590,D799,L699,U923,L881,U893,R79,U327,L405,D669,L702,D612,R895,D132,R420,U958,L955,U993,L817,D492,R453,D342,L575,D253,R97,U54,R456,U748,L912,U661,L987,D182,L816,U218,R933,D797,L207,D71,R546,U578,L894,D536,L253,D525,L164,D673,R784,U915,L774,U586,R733,D80,L510,U449,L403,D915,L612,D325,L470,U179,L460,U405,R297,D803,R637,U893,R565,U952,R550,U936,R378,D932,L669
"""

func part1() {
    let lines = inputdata.components(separatedBy: "\n")
    guard lines.count == 2 else {
        print("Didn't get 2 lines")
        exit(EXIT_FAILURE)
    }
    let line1 = Wire(input: lines[0])
    let line2 = Wire(input: lines[1])
    let nearestIntersection = line1.intersect(of: line2).min() ?? Point()
    print("Neareset intersection was at point \(nearestIntersection)")
    print("Distance: \(nearestIntersection.manhattan)")
}

func part2() {
    let lines = inputdata.components(separatedBy: "\n")
    guard lines.count == 2 else {
        print("Didn't get 2 lines")
        exit(EXIT_FAILURE)
    }
    let line1 = Wire(input: lines[0])
    let line2 = Wire(input: lines[1])
    print("Shortest distance to intersection = \(line1.shortestDistance(to: line2))")
}

print("Running Unit Tests")
guard part1UnitTests(),
      part2UnitTests() else {
    print("Unit tests failed")
    exit(EXIT_FAILURE)
}

print("Running part1")
part1()
print("Running part2")
part2()
