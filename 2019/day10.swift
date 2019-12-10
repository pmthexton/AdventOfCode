import Foundation

struct Point: Equatable, Hashable {
    var x:Double = 0
    var y:Double = 0

    init(x: Int, y: Int) {
        self.x = Double(x)
        self.y = Double(y)
    }

    func angle(to point:Point) -> Double {
        // For expediency for part2 let's adjust the returned angle back by +90
        // degrees so that we treat 0deg as north.
        // Also add 360 and mod 360 to get an answer of 0-359
        // otherwise atan2 will give us a range of either 0-180, or -180-0
        let rawangle = (atan2(point.y-y, point.x-x) * 180 / Double.pi) + 90
        return (360 + rawangle).truncatingRemainder(dividingBy: 360)
    }

    func distance(to point:Point) -> Double {
        return sqrt(pow(abs(point.y-y),2) + pow(abs(point.x-x),2))
    }
}

extension Array where Element == Point {
    // This is a really, really slow way of doing it.
    // But I'm not aware of any approaches that would be quicker.
    func getVisiblePoints(from location:Point) -> [Double: Point] {
        var visible: [Double: Point] = [:]
        for point in self {
            if point == location {
                continue
            }
            let s = location.angle(to: point)
            if visible[s] == nil {
                visible[s] = point
            } else {
                // Store the closest!
                if location.distance(to: point) < location.distance(to: visible[s]!) {
                    visible[s] = point
                }
            }
        }
        return visible
    }

    func getVisibleMap() -> [Point: [Point]] {
        var res: [Point: [Point]] = [:]
        for point in self {
            res[point] = getVisiblePoints(from: point).map { $0.1 }
        }
        return res
    }
}

extension Dictionary where Key == Point, Value == [Point] {
    func getBestChoice() -> (key: Point, value: [Point])? {
        return self.max(by: { (arg0, arg1) -> Bool in
        let (_, lhs) = arg0
        let (_, rhs) = arg1
        return lhs.count < rhs.count
        })
    }
}

class Laser:Sequence {
    private var map: [Point]
    private var location: Point
    private var visible: [Double:Point]
    private var sortedkeys: [Double]
    private var lastidx: Int?
    
    init(at location: Point, on map: [Point] ) {
        self.map = map
        self.location = location
        self.visible = map.getVisiblePoints(from: location)
        self.sortedkeys = self.visible.keys.sorted(by: <)
    }
    
    func makeIterator() -> AnyIterator<Point> {
        var index = 0
        return AnyIterator {
            var asteroid: Point?
            
            if index < self.sortedkeys.count {
                asteroid = self.visible[self.sortedkeys[index]]
                index += 1
            } else {
                // We've gone 360. Let's rebuild the view in case
                // the Laser obliterated any asteroids. And set index
                // back to 1 for the next pass after this.
                index = 1
                self.visible = self.map.getVisiblePoints(from: self.location)
                if self.visible.count == 0 {
                    print("zomg! we destoryed *everything*! You MONSTERS!")
                    return nil
                }
                self.sortedkeys = self.visible.keys.sorted(by: <)
                asteroid = self.visible[self.sortedkeys[0]]
            }

            return asteroid
        }
    }
    
    func destroyAsteroid(at location:Point) -> Void {
        map.removeAll() { point in
            point == location
        }
    }
}

func loadmap(from string:String) -> [Point] {
    var points:[Point] = []

    let dlines = string.components(separatedBy: "\n")

    for (y,line) in dlines.enumerated() {
        for (x,a) in line.enumerated() {
            if a == "#" {
                let p = Point(x: x, y: y)
                points.append(p)
            }
        }
    }

    return points
}

func p1unitTests() -> Bool {
    let tests = [
        (data: """
        .#..##.###...#######
        ##.############..##.
        .#.######.########.#
        .###.#######.####.#.
        #####.##.#.##.###.##
        ..#####..#.#########
        ####################
        #.####....###.#.#.##
        ##.#################
        #####.##.###..####..
        ..######..##.#######
        ####.##.####...##..#
        .#####..#.######.###
        ##...#.##########...
        #.##########.#######
        .####.#.###.###.#.##
        ....##.##.###..#####
        .#.#.###########.###
        #.#.#.#####.####.###
        ###.##.####.##.#..##
        """,
        choice: Point(x: 11, y: 13)),
        (data: """
        .#..#..###
        ####.###.#
        ....###.#.
        ..###.##.#
        ##.##.#.#.
        ....###..#
        ..#.#..#.#
        #..#.#.###
        .##...##.#
        .....#.#..
        """,
        choice: Point(x: 6, y: 3)),
        (data: """
        #.#...#.#.
        .###....#.
        .#....#...
        ##.#.#.#.#
        ....#.#.#.
        .##..###.#
        ..#...##..
        ..##....##
        ......#...
        .####.###.
        """,
        choice: Point(x: 1, y: 2)),
        (data: """
        ......#.#.
        #..#.#....
        ..#######.
        .#.#.###..
        .#..#.....
        ..#....#.#
        #..#....#.
        .##.#..###
        ##...#..#.
        .#....####
        """,
        choice: Point(x: 5, y: 8)
        )
    ]
    for test in tests {
        let map = loadmap(from: test.data)
        let mapviews = map.getVisibleMap()
        let bestchoice = mapviews.getBestChoice()!
        guard bestchoice.key == test.choice else {
            print("Test failed, expected \(test.choice) but got \(bestchoice.key)")
            return false
        }
        print("Test passed. \(bestchoice.key) = \(bestchoice.value.count)")
    }
    return true
}

func laserTests() -> Bool {
    let tests = [
        (data: """
        .#....#####...#..
        ##...##.#####..##
        ##...#...#.#####.
        ..#.....#...###..
        ..#.#.....#....##
        """,
        choice: Point(x: 8, y: 3),
        targets: [
            Point(x: 8, y: 1),
            Point(x: 9, y: 0),
            Point(x: 9, y: 1),
            Point(x: 10, y: 0),
            Point(x: 9, y: 2),
            Point(x: 11, y: 1),
            Point(x: 12, y: 1),
            Point(x: 11, y: 2),
            Point(x: 15, y: 1),
            Point(x: 12, y: 2),
            Point(x: 13, y: 2),
            Point(x: 14, y: 2),
            Point(x: 15, y: 2),
            Point(x: 12, y: 3),
            Point(x: 16, y: 4),
            Point(x: 15, y: 4),
            Point(x: 10, y: 4),
            Point(x: 4, y: 4),
            Point(x: 2, y: 4),
            Point(x: 2, y: 3),
            Point(x: 0, y: 2),
            Point(x: 1, y: 2),
            Point(x: 0, y: 1),
            Point(x: 1, y: 1),
            Point(x: 5, y: 2),
            Point(x: 1, y: 0),
            Point(x: 5, y: 1),
            Point(x: 6, y: 1),
            Point(x: 6, y: 0),
            Point(x: 7, y: 0),
            Point(x: 8, y: 0),
            Point(x: 10, y: 1),
            Point(x: 14, y: 0),
            Point(x: 16, y: 1),
            Point(x: 13, y: 3),
            Point(x: 14, y: 3),
        ])
    ]
    for test in tests {
        let map = loadmap(from: test.data)
        let mapviews = map.getVisibleMap()
        let station = mapviews.getBestChoice()!.key
        guard station == test.choice else {
            print("Unit test failed. Expected \(test.choice) but got \(station)")
            return false
        }
        print("Unit test passed. \(station)")
        let laser = Laser(at: station, on: map)
        for (n,point) in laser.makeIterator().enumerated() {
            guard point == test.targets[n] else {
                print("We're aiming at the wrong asteroid. Expected \(test.targets[n]) but got \(point)")
                return false
            }
            laser.destroyAsteroid(at: point)
        }
        print("Laser test passed")
    }
    return true
}

func part1() {
    let data = """
    .............#..#.#......##........#..#
    .#...##....#........##.#......#......#.
    ..#.#.#...#...#...##.#...#.............
    .....##.................#.....##..#.#.#
    ......##...#.##......#..#.......#......
    ......#.....#....#.#..#..##....#.......
    ...................##.#..#.....#.....#.
    #.....#.##.....#...##....#####....#.#..
    ..#.#..........#..##.......#.#...#....#
    ...#.#..#...#......#..........###.#....
    ##..##...#.#.......##....#.#..#...##...
    ..........#.#....#.#.#......#.....#....
    ....#.........#..#..##..#.##........#..
    ........#......###..............#.#....
    ...##.#...#.#.#......#........#........
    ......##.#.....#.#.....#..#.....#.#....
    ..#....#.###..#...##.#..##............#
    ...##..#...#.##.#.#....#.#.....#...#..#
    ......#............#.##..#..#....##....
    .#.#.......#..#...###...........#.#.##.
    ........##........#.#...#.#......##....
    .#.#........#......#..........#....#...
    ...............#...#........##..#.#....
    .#......#....#.......#..#......#.......
    .....#...#.#...#...#..###......#.##....
    .#...#..##................##.#.........
    ..###...#.......#.##.#....#....#....#.#
    ...#..#.......###.............##.#.....
    #..##....###.......##........#..#...#.#
    .#......#...#...#.##......#..#.........
    #...#.....#......#..##.............#...
    ...###.........###.###.#.....###.#.#...
    #......#......#.#..#....#..#.....##.#..
    .##....#.....#...#.##..#.#..##.......#.
    ..#........#.......##.##....#......#...
    ##............#....#.#.....#...........
    ........###.............##...#........#
    #.........#.....#..##.#.#.#..#....#....
    ..............##.#.#.#...........#.....
    """

    let map = loadmap(from: data)
    let mapviews = map.getVisibleMap()
    let bestchoice = mapviews.getBestChoice()!

    print("Finished. \(bestchoice.key) can view \(bestchoice.value.count) other asteroids")
}

func part2() {
        let data = """
    .............#..#.#......##........#..#
    .#...##....#........##.#......#......#.
    ..#.#.#...#...#...##.#...#.............
    .....##.................#.....##..#.#.#
    ......##...#.##......#..#.......#......
    ......#.....#....#.#..#..##....#.......
    ...................##.#..#.....#.....#.
    #.....#.##.....#...##....#####....#.#..
    ..#.#..........#..##.......#.#...#....#
    ...#.#..#...#......#..........###.#....
    ##..##...#.#.......##....#.#..#...##...
    ..........#.#....#.#.#......#.....#....
    ....#.........#..#..##..#.##........#..
    ........#......###..............#.#....
    ...##.#...#.#.#......#........#........
    ......##.#.....#.#.....#..#.....#.#....
    ..#....#.###..#...##.#..##............#
    ...##..#...#.##.#.#....#.#.....#...#..#
    ......#............#.##..#..#....##....
    .#.#.......#..#...###...........#.#.##.
    ........##........#.#...#.#......##....
    .#.#........#......#..........#....#...
    ...............#...#........##..#.#....
    .#......#....#.......#..#......#.......
    .....#...#.#...#...#..###......#.##....
    .#...#..##................##.#.........
    ..###...#.......#.##.#....#....#....#.#
    ...#..#.......###.............##.#.....
    #..##....###.......##........#..#...#.#
    .#......#...#...#.##......#..#.........
    #...#.....#......#..##.............#...
    ...###.........###.###.#.....###.#.#...
    #......#......#.#..#....#..#.....##.#..
    .##....#.....#...#.##..#.#..##.......#.
    ..#........#.......##.##....#......#...
    ##............#....#.#.....#...........
    ........###.............##...#........#
    #.........#.....#..##.#.#.#..#....#....
    ..............##.#.#.#...........#.....
    """

    let map = loadmap(from: data)
    let mapviews = map.getVisibleMap()
    let station = mapviews.getBestChoice()!.key
    let laser = Laser(at: station, on: map)
    var asteroid: Point?
    for (n,point) in laser.makeIterator().enumerated() {
        if n == 199 {
            asteroid = point
            break
        }
        laser.destroyAsteroid(at: point)
    }
    if let asteroid = asteroid {
        print("200th asteroid = \(asteroid)")
        print("Answer = \((asteroid.x * 100)+asteroid.y)")
    }
}

guard p1unitTests(), laserTests() else {
    print("Oops. Tests failed.")
    exit(EXIT_FAILURE)
}

part1()
part2()