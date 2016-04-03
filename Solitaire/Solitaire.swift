//
//  Solitaire.swift
//  Solitaire
//
//  Created by Wayne Cochran on 4/3/16.
//  Copyright © 2016 Wayne Cochran. All rights reserved.
//

import Foundation

class Solitaire {
    var stock : [Card]
    var waste : [Card]
    var foundation : [[Card]]
    var tableau : [[Card]]
    
    private var faceUpCards : Set<Card>;
    
    init() {
        stock = Card.deck()
        waste = []
        foundation = [[],[],[],[]]
        tableau = [[], [], [], [], [], [], []]
        faceUpCards = []
    }
    
    init(dictionary dict : [String : AnyObject]) { // for retrieving from plist
        let stockArray = dict["stock"] as! [[String : AnyObject]]
        stock = stockArray.map{Card(dictionary: $0)}
        
        let wasteArray = dict["waste"] as! [[String : AnyObject]]
        waste = wasteArray.map{Card(dictionary: $0)}
        
        let foundationArray = dict["foundation"] as! [[[String : AnyObject]]]
        foundation = [[],[],[],[]]
        for f in 0 ..< 4 {
            foundation[f] = foundationArray[f].map{Card(dictionary: $0)}
        }
        
        let tableauArray = dict["tableau"] as! [[[String : AnyObject]]]
        tableau = [[], [], [], [], [], [], []]
        for t in 0 ..< 7 {
            tableau[t] = tableauArray[t].map{Card(dictionary: $0)}
        }
        
        let faceUpCardsArray = dict["faceUpCards"] as! [[String : AnyObject]]
        faceUpCards = []
        faceUpCardsArray.forEach{
            faceUpCards.insert(Card(dictionary:$0))
        }
    }
    
    func toDictionary() -> [String : AnyObject] {  // for storing in plist
        let stockArray = stock.map{$0.toDictionary()}
        let wasteArray = waste.map{$0.toDictionary()}
        let foundationArray = foundation.map {
            $0.map{$0.toDictionary()}
        }
        let tableauArray = tableau.map {
            $0.map{$0.toDictionary()}
        }
        let faceUpCardsArray = faceUpCards.map{$0.toDictionary()}
        return [
            "stock" : stockArray,
            "waste" : wasteArray,
            "foundation" : foundationArray,
            "tableau" : tableauArray,
            "faceUpCards" : faceUpCardsArray
        ]
    }
    
    func isCardFaceUp(card : Card) -> Bool {
        return faceUpCards.contains(card)
    }
    
    func collectAllCardsIntoStock() { // order not important
        stock += waste
        waste.removeAll()
        for i in 0 ..< 4 {
            stock += foundation[i]
            foundation[i].removeAll()
        }
        for i in 0 ..< 7 {
            stock += tableau[i]
            tableau[i].removeAll()
        }
        faceUpCards.removeAll()
    }
    
    func collectWasteCardsIntoStock() { // order is important
        let n = waste.count
        for _ in 0 ..< n {
            let card = waste.popLast()!
            stock.append(card)
            faceUpCards.remove(card)
        }
    }
    
    func shuffeStock(numShuffles num : Int) {
        let n = stock.count
            for _ in 1 ... num {
                for j in 0 ..< n {
                    let k = Int(arc4random_uniform(UInt32(n)))
                    (stock[j], stock[k]) = (stock[k], stock[j])
                }
        }
    }
    
    func dealCardsFromStockToTableaux() {
        assert(stock.count == 52)
        for i in 0 ..< 7 {
            for j in i ..< 7 {
                let card = stock.popLast()!
                tableau[j].append(card)
                if i == j {
                    faceUpCards.insert(card) // last card is face up
                }
                
            }
        }
    }
    
    func freshGame() {
        collectAllCardsIntoStock()
        shuffeStock(numShuffles: 5)
        dealCardsFromStockToTableaux()
    }
    
    func fanBeginningWithCard(card : Card) -> ArraySlice<Card>? {
        for i in 0 ..< 7 {
            let cards = tableau[i]
            let numCards = cards.count
            for j in 0 ..< numCards {
                if card == cards[j] {
                    return cards[j ..< numCards]
                }
            }
        }
        return nil
    }
    
    func canDropCard(card : Card, onFoundation i : Int) -> Bool {
        if foundation[i].isEmpty {
            return card.rank == ACE
        } else {
            let topCard = foundation[i].last!
            return card.suit == topCard.suit && card.rank == topCard.rank + 1
        }
    }
    
    func didDropCard(card : Card, onFoundation i : Int) {
        removeTopCard(card)  // remove card from wherever it came
        foundation[i].append(card)
    }
    
    func canDropCard(card : Card, onTableau i : Int) -> Bool {
        if tableau[i].isEmpty {
            return card.rank == KING
        } else {
            let topCard = tableau[i].last!
            return isCardFaceUp(topCard) && card.rank == topCard.rank - 1 && card.isSameColor(topCard)
        }
    }
    
    func didDropCard(card : Card, onTableau i : Int) {
        removeTopCard(card)  // remove card from wherever it came
        tableau[i].append(card)
    }
    
    func canDropFan(cards : [Card], onTableau i : Int) -> Bool {
        let card = cards[0]
        return canDropCard(card, onTableau: i)
    }
    
    func didDropFan(cards : [Card], onTableau i : Int) {
        
    }
    
    //
    // Find card that is known to be on the top of either
    // the waste, a foundation stack , or a tableaux and remove it.
    // We return the card stack it was removed from (for potential undo).
    //
    private func removeTopCard(card : Card) -> [Card]? {
        if card == waste.last {
            waste.popLast()
            return waste
        }
        for i in 0 ..< 4 {
            if card == foundation[i].last {
                foundation[i].popLast()
                return foundation[i]
            }
        }
        for i in 0 ..< 7 {
            if card == tableau[i].last {
                tableau[i].popLast()
                return tableau[i]
            }
        }
        return nil // this should not happen
    }
    
    private func removeTopCards(cards : [Card]) -> [Card]? {
        let card = cards[0]
        
        // XXX
        
        return nil  // this should not happen
    }
    
}







