import Foundation

// I had some assistance here. I was reading the reddit for
// today's AOC and spotted some phrases I vaguely remembered
// from A-level maths (short for mathematicS, for our American
// cousins 😜) about greatest common divisor / largest common
// multiplier. Looks like the right-ish approach.
class Maths {
    // Find the greatest common divisor of two numbers
    static func gcd(_ val1: Int, _ val2: Int) -> Int {
        var a = val1
        var b = val2
        while b != 0 {
            (a, b) = (b, a % b)
        }

        return abs(a)
    }

    // Find the greatest common divisor of an array of numbers
    static func gcd(_ val: [Int]) -> Int {
        return val.reduce(0) { gcd($0, $1) }
    }

    // Find the largest common multiplier of two numbers
    static func lcm(_ val1: Int, _ val2: Int) -> Int {
        return (val1 / gcd(val1,val2)) * val2
    }

    // Find the LCM of an array of numbers
    static func lcm(_ val: [Int]) -> Int {
        return val.reduce(val[0]) { lcm($0, $1) }
    }
}

struct Point: Equatable {
    var x = 0
    var y = 0
    var z = 0
}

struct Moon: Equatable {
    var pos: Point
    var vel: Point

    func energy() -> Int {
        let energy = (abs(pos.x)+abs(pos.y)+abs(pos.z))
                     * (abs(vel.x)+abs(vel.y)+abs(vel.z))
        return energy
    }

    mutating func affectVelocity(from moon:Moon) {
        vel.z += getVelocityAdjustment(them: moon.pos.z, us: pos.z)
        vel.y += getVelocityAdjustment(them: moon.pos.y, us: pos.y)
        vel.x += getVelocityAdjustment(them: moon.pos.x, us: pos.x)
    }

    mutating func move() {
        pos.z += vel.z
        pos.y += vel.y
        pos.x += vel.x
    }

    private func getVelocityAdjustment(them: Int, us: Int) -> Int {
        if them > us {
            return 1
        } else if them < us {
            return -1
        }
        return 0
    }
}

extension Array where Element == Moon {
    mutating func move() {
        for i in 0..<self.count {
            for j in i+1..<self.count {
                self[i].affectVelocity(from: self[j])
                self[j].affectVelocity(from: self[i])
            }
        }

        for i in 0..<self.count {
            self[i].move()
        }
    }

    // To calculate the cycles taken we need to first find
    // out how many cycles it takes for each axis (and it's
    // associated velocity) to work back to where it started
    // from by finding the LCM for each axis & velocity to
    // repeat when moving manually.
    // Once we know that value for each axis, we take the LCM
    // for the cycle of each of them.
    func calculateCycle() -> Int {
        var moons = self // Take a copy so we can reset back to start each time
        var axiscycles = [0,0,0,0,0,0]
        var count = 0
        repeat {
            count += 1
            moons.move()
            // This bit is really ugly. But I don't care enough to try
            // and refactor it in to tidy code. It's functional enough
            // for now, unless it crops up in a later AOC day!
            if axiscycles[0] == 0 && axiscycles[3] == 0 {
                let a = moons.map { ($0.pos.x, $0.vel.x) }
                let b = self.map { ($0.pos.x, $0.vel.x) }
                if a[0] == b[0] && a[1] == b[1] {
                    axiscycles[0] = count
                    axiscycles[3] = count
                }
            }
            if axiscycles[1] == 0 && axiscycles[4] == 0 {
                let a = moons.map { ($0.pos.y, $0.vel.y) }
                let b = self.map { ($0.pos.y, $0.vel.y) }
                if a[0] == b[0] && a[1] == b[1] {
                    axiscycles[1] = count
                    axiscycles[4] = count
                }
            }
            if axiscycles[2] == 0 {
                let a = moons.map { ($0.pos.z, $0.vel.z) }
                let b = self.map { ($0.pos.z, $0.vel.z) }
                if a[0] == b[0] && a[1] == b[1] {
                    axiscycles[2] = count
                    axiscycles[5] = count
                }
            }

            if !axiscycles.contains(0) {
                break
            }

        } while(moons != self) // We'll break way earlier than this

        return Maths.lcm(axiscycles)
    }

    func totalEnergy() -> Int {
        return self.reduce(0) { sum, moon in
            return sum + moon.energy()
        }
    }
}

func p1UnitTests() -> Bool {
    let tests = [
        (moons: [
             Moon(pos: Point(x: -1, y: 0, z: 2), vel: Point()),
             Moon(pos: Point(x: 2, y: -10, z: -7), vel: Point()),
             Moon(pos: Point(x: 4, y: -8, z: 8), vel: Point()),
             Moon(pos: Point(x: 3, y: 5, z: -1), vel: Point())
            ],
         steps: 10,
         expected: [
             Moon(pos: Point(x: 2, y: 1, z: -3), vel: Point(x: -3, y: -2, z: 1)),
             Moon(pos: Point(x: 1, y: -8, z: 0), vel: Point(x: -1, y: 1, z: 3)),
             Moon(pos: Point(x: 3, y: -6, z: 1), vel: Point(x: 3, y: 2, z: -3)),
             Moon(pos: Point(x: 2, y: 0, z: 4), vel: Point(x: 1, y: -1, z: -1))
         ],
         energy: 179
        ),
        (moons: [
             Moon(pos: Point(x: -8, y: -10, z: 0), vel: Point()),
             Moon(pos: Point(x: 5, y: 5, z: 10), vel: Point()),
             Moon(pos: Point(x: 2, y: -7, z: 3), vel: Point()),
             Moon(pos: Point(x: 9, y: -8, z: -3), vel: Point())
            ],
         steps: 100,
         expected: [
             Moon(pos: Point(x: 8, y: -12, z: -9), vel: Point(x: -7, y: 3, z: 0)),
             Moon(pos: Point(x: 13, y: 16, z: -3), vel: Point(x: 3, y: -11, z: -5)),
             Moon(pos: Point(x: -29, y: -11, z: -1), vel: Point(x: -3, y: 7, z: 4)),
             Moon(pos: Point(x: 16, y: -13, z: 23), vel: Point(x: 7, y: 1, z: 1))
         ],
         energy: 1940
        )
    ]
    for var test in tests {
        for _ in 0..<test.steps {
            test.moons.move()
        }
        guard test.moons == test.expected else {
            print("Moons not in expected locations")
            print("==== positions ======")
            test.moons.forEach {
                print($0)
            }
            print("==== expected =======")
            test.expected.forEach {
                print($0)
            }
            return false
        }
        guard test.energy == test.moons.totalEnergy() else {
            print("Unit test failed. Expected energy \(test.energy) but got \(test.moons.totalEnergy())")
            return false
        }
    }
    print("Part 1 Unit tests passed")
    return true
}

func p2UnitTests() -> Bool {
    let tests = [
        (moons: [
             Moon(pos: Point(x: -1, y: 0, z: 2), vel: Point()),
             Moon(pos: Point(x: 2, y: -10, z: -7), vel: Point()),
             Moon(pos: Point(x: 4, y: -8, z: 8), vel: Point()),
             Moon(pos: Point(x: 3, y: 5, z: -1), vel: Point())
            ],
         steps: 2772
        ),
        (moons: [
             Moon(pos: Point(x: -8, y: -10, z: 0), vel: Point()),
             Moon(pos: Point(x: 5, y: 5, z: 10), vel: Point()),
             Moon(pos: Point(x: 2, y: -7, z: 3), vel: Point()),
             Moon(pos: Point(x: 9, y: -8, z: -3), vel: Point())
            ],
         steps: 4686774924
        )
    ]
    for test in tests {
        let moves = test.moons.calculateCycle()
        guard moves == moves else {
            print("Unit test failed. Got \(moves) but expected \(test.steps)")
            return false
        }
    }
    print("Part 2 Unit tests passed")
    return true
}

func part1() {
    print("Part 1")
    var moons = [
        Moon(pos: Point(x: -4, y: 3, z: 15), vel: Point()),
        Moon(pos: Point(x: -11, y: -10, z: 13), vel: Point()),
        Moon(pos: Point(x: 2, y: 2, z: 18), vel: Point()),
        Moon(pos: Point(x: 7, y: -1, z: 0), vel: Point()),
    ]
    for _ in 0..<1000 {
        moons.move()
    }
    print("=== Total energy in system: \(moons.totalEnergy())")
}

func part2() {
    print("Part 2")
    let moons = [
        Moon(pos: Point(x: -4, y: 3, z: 15), vel: Point()),
        Moon(pos: Point(x: -11, y: -10, z: 13), vel: Point()),
        Moon(pos: Point(x: 2, y: 2, z: 18), vel: Point()),
        Moon(pos: Point(x: 7, y: -1, z: 0), vel: Point()),
    ]
    print("=== Total moves required to get back to start = ", moons.calculateCycle())
}

_ = p1UnitTests()
_ = p2UnitTests()
part1()
part2()
