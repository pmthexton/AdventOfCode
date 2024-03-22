//: [Previous](@previous)

import Foundation

enum Card: String, CaseIterable, Comparable {
    case star = "*"
    case two = "2"
    case three = "3"
    case four = "4"
    case five = "5"
    case six = "6"
    case seven = "7"
    case eight = "8"
    case nine = "9"
    case t = "T"
    case j = "J"
    case q = "Q"
    case k = "K"
    case a = "A"
    
    func value() -> Int {
        Card.allCases.firstIndex(of: self)!
    }
    
    static func < (lhs: Card, rhs: Card) -> Bool {
        lhs.value() < rhs.value()
    }
}

extension Array where Element == Card {
    func showHand() -> String {
        self.compactMap { $0.rawValue }.joined()
    }
}

struct Hand: Comparable {
    static func < (lhs: Hand, rhs: Hand) -> Bool {
        let lhsName = lhs.name()
        let rhsName = rhs.name()
        if lhsName == rhsName {
            for (idx, card) in lhs.cards.enumerated() {
                if card != rhs.cards[idx] {
                    return card.value() < rhs.cards[idx].value()
                }
            }
            // shouldn't ever get here..
            return lhs.cards[0].value() < rhs.cards[0].value()
        }
        return lhs.name().rawValue < rhs.name().rawValue
    }
    
    enum Category: Int {
        case HighCard
        case OnePair
        case TwoPair
        case ThreeOfAKind
        case FullHouse
        case FourOfAKind
        case FiveOfAKind
    }
    let raw: String
    let cards: [Card]
    let bid: Int
    
    init(from input: String, _ joker: Bool = false) {
        let details = input.split(separator: " ")
        self.raw = String(details[0])
        self.cards = details[0].replacing("J", with: "*").map {
            Card.init(rawValue: String($0))!
        }
        self.bid = Int(details[1])!
    }
    
    func name() -> Category {
        var dups = Dictionary(grouping: cards, by: \.rawValue)
            .filter {
                $1.first! != Card.star && $1.count > 1
            }.values.sorted(by: {$0.count > $1.count})
        
        let jokers = cards.filter { $0 == Card.star }.count
        var rep: Card?
        switch jokers {
        case 5:
            rep = Card.a
        case 4:
            rep = cards.max()!
        case 3:
            rep = Card.a
            if dups.count > 0 {
                rep = dups.first!.first!
            }
        case 1,2:
            if dups.count > 0 {
                rep = dups.first!.first!
            } else {
                rep = cards.max()!
            }
//            print(jokers,"jokers replacing with",rep!)
        default:
            rep = nil
        }
        
        dups = Dictionary(grouping: cards.map {
            if let rep = rep {
                return $0 == Card.star ? rep : $0
            }
            return $0
        }, by: \.rawValue).values.filter {
            $0.count > 1
        }.sorted(by: {$0.count > $1.count})
//
//        if let rep = rep {
//            print(raw,"became",dups)
//        }
//    
        switch dups.count {
        case 2:
            if dups.map({ $0.count }).contains(3) {
                return .FullHouse
            }
            return .TwoPair
        case 1:
            switch dups.first!.count {
            case 5:
                return .FiveOfAKind
            case 4:
                return .FourOfAKind
            case 3:
                return .ThreeOfAKind
            default:
                return .OnePair
            }
        default:
            return .HighCard
        }
    }
}

//let hands = Utils.loadLines(file: "exampledata")!.map(Hand.init(from:)).sorted()

let hands = Utils.loadLines(file: "puzzleinput")!.map {
    Hand.init(from: $0, true)
}.sorted()

let answer = hands.enumerated().reduce(0, {res, hand in
    res + ((hand.offset + 1) * hand.element.bid)
})

print(answer)

//let last = Utils.loadLines(file: "puzzleinput")![0..<58].map {
//    Hand.init(from: $0, true)
//}.last!
//print(last.raw,last.name())

//for i in 550...553 {
//    
//    var hands = Utils.loadLines(file: "puzzleinput")![0..<i].map { Hand.init(from: $0, true)}
//    print("last card", hands.last!.raw, hands.last!.name())
//    hands = hands.sorted()
//    
//    let answer = hands.enumerated().reduce(0, { res, hand in
//        res + ((hand.offset + 1) * hand.element.bid)
//    })
//    
//    print(answer,i)
//}

//: [Next](@next)
