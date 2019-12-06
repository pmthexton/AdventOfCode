import Foundation

let file = String(data: FileManager.default.contents(atPath: "day6input") ?? Data(), encoding: .utf8)!

func getObjects() -> [String:[String]] {
    var objects: [String:[String]] = [:]

    for orbit in file.components(separatedBy: "\n") {
        let a = orbit.components(separatedBy: ")")
        guard a.count == 2 else {
            print("Bad input")
            print(a)
            exit(EXIT_FAILURE)
        }
        if objects[a[0]] == nil {
            objects[a[0]] = [a[1]]
        } else {
            objects[a[0]]!.append(a[1])
        }
    }
    return objects
}

var objects = getObjects()

func countOrbits(for name:String, inheriting indirect:Int, in objects:[String:[String]])
    -> Int {
    var count = indirect
    guard let orbit = objects[name] else {
        return indirect
    }
    for satellite in orbit {
        count += countOrbits(for: satellite, inheriting: indirect + 1, in: objects)
    }
    return count
}

print("Number of indirect and direct orbits in our map",countOrbits(for: "COM", inheriting: 0, in: objects))

var myorbit = objects.filter { $0.value.contains("YOU") }
let me = myorbit.keys[myorbit.startIndex]
var santaorbit = objects.filter { $0.value.contains("SAN") }
let san = santaorbit.keys[santaorbit.startIndex]

// We could calculate jumping both ourselves and santa at the same time,
// but we don't know that the common point back towards COM is exactly in
// the center.  So rather than try to come up with a sophisticated algorithm
// map Santa's path back to COM, jump ourselves back until we end up in the same
// route, and then work out how many transfers santa made to get to that point in the
// route
var maphome: [String:[String]] = [:]
while(maphome["COM"] == nil) {
    // map merge wants to know how to deal with duplicate keys
    // but there won't be any. So it's really just a placeholder.
    maphome.merge(santaorbit) { k1, _ in
        return k1
    }
    santaorbit = objects.filter { $0.value.contains(santaorbit.keys[santaorbit.startIndex])}
}

var transfers = 0
// Jump orbits until we get to a common point
while(maphome[myorbit.keys[myorbit.startIndex]] == nil) {
    transfers += 1
    myorbit = objects.filter { $0.value.contains(myorbit.keys[myorbit.startIndex]) }
}
print("We got to a common point in \(transfers) orbital transfers")
// Just need to add how many transfers it would be for santa to reach the same point
santaorbit = objects.filter { $0.value.contains("SAN") }
while(myorbit[santaorbit.keys[santaorbit.startIndex]] == nil) {
    transfers += 1
    santaorbit = objects.filter { $0.value.contains(santaorbit.keys[santaorbit.startIndex])}
}
print("We reached santa in \(transfers) ortibal transfers")
