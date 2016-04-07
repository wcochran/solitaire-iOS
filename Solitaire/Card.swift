//
//  Card.swift
//  Solitaire
//
//  Created by Wayne Cochran on 4/3/16.
//  Copyright © 2016 Wayne Cochran. All rights reserved.
//

import Foundation

enum Suit : UInt8 {
    case SPADES = 0
    case CLUBS  = 1
    case DIAMONDS = 2
    case HEARTS = 3
}


let ACE   : UInt8 = 1
let JACK  : UInt8 = 11
let QUEEN : UInt8 = 12
let KING  : UInt8 = 13

let suitStrings = ["♠︎", "♣︎", "♦︎", "♥︎"]
let rankStrings = [
    "", "A", "2", "3", "4", "5", "6", "7",
    "8", "9", "10", "J", "Q", "K"
]

func ==(left: Card, right: Card) -> Bool {
    return left.suit == right.suit && left.rank == right.rank
}

struct Card : Hashable {
    let suit : Suit
    let rank : UInt8 // 1 .. 13
    
    var description : String {
        return rankStrings[Int(rank)] + suitStrings[Int(suit.rawValue)]
    }
    
    var hashValue: Int {
        return Int(suit.rawValue*13 + rank - 1)
    }
    
    init(suit s : Suit, rank r : UInt8) {
        suit = s;
        rank = r
    }
    
    init(dictionary dict : [String : AnyObject]) { // to retrieve from plist
        suit = Suit(rawValue: (dict["suit"] as! NSNumber).unsignedCharValue)!
        rank = (dict["rank"] as! NSNumber).unsignedCharValue
    }
    
    func toDictionary() -> [String : AnyObject] { // to store in plist
        return [
            "suit" : NSNumber(unsignedChar: suit.rawValue),
            "rank" : NSNumber(unsignedChar: rank)
        ]
    }
    
    func isBlack() -> Bool {
        return suit == Suit.SPADES || suit == Suit.CLUBS
    }
    
    func isRed() -> Bool {
        return !isBlack()
    }
    
    func isSameColor(other : Card) -> Bool {
        return isBlack() ? other.isBlack() : other.isRed()
    }
    
    static func deck() -> [Card] {
        var d : [Card] = []
        for s in 0 ... 3 {
            for r in 1 ... 13 {
                d.append(Card(suit: Suit(rawValue: UInt8(s))!, rank: UInt8(r)))
            }
        }
        return d
    }
    
}