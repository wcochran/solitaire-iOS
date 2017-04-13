//
//  Solitaire.swift
//  Solitaire
//
//  Created by Wayne Cochran on 4/3/16.
//  Copyright © 2016 Wayne Cochran. All rights reserved.
//

import Foundation

enum CardStack {
    case stock
    case waste
    case foundation(Int)
    case tableau(Int)
}

class Solitaire {
    var stock : [Card]
    var waste : [Card]
    var foundation : [[Card]]
    var tableau : [[Card]]
    
    fileprivate var faceUpCards : Set<Card>;
    
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
    
    func isCardFaceUp(_ card : Card) -> Bool {
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
    
    func undoCollectWasteCardsIntoStock() {
        while !stock.isEmpty {
            let card = stock.popLast()!
            faceUpCards.insert(card)
            waste.append(card)
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
    
    func fanBeginningWithCard(_ card : Card) -> [Card]? {
        for i in 0 ..< 7 {
            let cards = tableau[i]
            let numCards = cards.count
            for j in 0 ..< numCards {
                if card == cards[j] {
                    var fan : [Card] = []  // could have used ArraySlice
                    for k in j ..< numCards {  // but they're kinda evil
                        fan.append(cards[k])
                    }
                    return fan
                }
            }
        }
        return nil
    }
    
    func canDropCard(_ card : Card, onFoundation i : Int) -> Bool {
        if foundation[i].isEmpty {
            return card.rank == ACE
        } else {
            let topCard = foundation[i].last!
            return card.suit == topCard.suit && card.rank == topCard.rank + 1
        }
    }
    
    //
    // Return stack that card came from (for undo information)
    //
    func didDropCard(_ card : Card, onFoundation i : Int) -> CardStack {
        let cardStack = findAndRemoveCardFromStack(card)
        foundation[i].append(card)
        return cardStack
    }
    
    func undoDidDropCard(_ card : Card, fromStack source : CardStack, onFoundation i : Int) {
        let card = foundation[i].popLast()!
        switch(source) {
        case .waste:
            waste.append(card)
        case .foundation(let index):
            foundation[index].append(card)
        case .tableau(let index):
            tableau[index].append(card)
        default: break
        }
    }
    
    func canDropCard(_ card : Card, onTableau i : Int) -> Bool {
        if tableau[i].isEmpty {
            return card.rank == KING
        } else {
            let topCard = tableau[i].last!
            return isCardFaceUp(topCard) && card.rank == topCard.rank - 1 && !card.isSameColor(topCard)
        }
    }
 
    //
    // Return stack that card came from (for undo information)
    //
    func didDropCard(_ card : Card, onTableau i : Int) -> CardStack {
        let cardStack = findAndRemoveCardFromStack(card)
        tableau[i].append(card)
        return cardStack
    }
   
    func undoDidDropCard(_ card : Card, fromStack source : CardStack, onTableau i : Int) {
        let card = tableau[i].popLast()!
        switch(source) {
        case .waste:
            waste.append(card)
        case .foundation(let index):
            foundation[index].append(card)
        case .tableau(let index):
            tableau[index].append(card)
        default: break
        }
    }
    

    func canDropFan(_ cards : [Card], onTableau i : Int) -> Bool {
        if let card = cards.first {
            return canDropCard(card, onTableau: i)
        }
        return false;
    }
 
    func didDropFan(_ cards : [Card], onTableau i : Int) -> CardStack {
        let cardStack = findAndRemoveCardFanFromStack(cards)
        tableau[i] += cards
        return cardStack
    }
    
    func undoDidDropFan(_ cards : [Card], fromStack source : CardStack, onTableau i : Int) {
        tableau[i].removeLast(cards.count)
        switch(source) {
        case .foundation(let index):
            foundation[index] += cards;
        case .tableau(let index):
            tableau[index] += cards
        default: break
        }
    }
    
    func canFlipCard(_ card : Card) -> Bool {
        if isCardFaceUp(card) {
            return false
        } else {
            for i in 0 ..< 7 {
                let topCard = tableau[i].last
                if card == topCard {
                    return true
                }
            }
        }
        return false
    }
    
    func didFlipCard(_ card : Card) {
        faceUpCards.insert(card)
    }
    
    func undoFlipCard(_ card : Card) {
        faceUpCards.remove(card)
    }
    
    func canDealCard() -> Bool {
        return stock.count > 0
    }
    
    func didDealCard() {
        let card = stock.popLast()!
        waste.append(card)
        faceUpCards.insert(card)
    }
    
    func undoDealCard() {
        let card = waste.popLast()!
        faceUpCards.remove(card)
        stock.append(card)
    }
    
    //
    // Deal 0 to num cards from stock to waste.
    // Returns cards actually dealt (so view can animate them, and
    // we home many cards were dealt for an undo).
    //
    func dealCards(_ num : Int) -> [Card] {
        var cards : [Card] = []
        let max = min(stock.count, num)
        for _ in 0 ..< max {
            let card = stock.popLast()!
            faceUpCards.insert(card)
            cards.append(card)
            waste.append(card)
        }
        return cards
    }
    
    func undoDealCards(_ num : Int) {
        for _ in 0 ..< num {
            let card = waste.popLast()!
            faceUpCards.remove(card)
            stock.append(card)
        }
    }
    
    func gameWon() -> Bool {
        for i in 0 ..< 4 {
            if foundation[i].count != 13 {
                return false
            }
        }
        return true
    }
    
    func dump() {  // dump state of model to console (for diagnostics)
        print("=================")
        print("stock:")
        stock.forEach {card in print(card.description + ", ", terminator:"")}
        print()
        print("waste:")
        waste.forEach {card in print(card.description + ", ", terminator:"")}
        print()
        for (i, cards) in foundation.enumerated() {
            print("foundation[\(i)]:")
            cards.forEach {card in print(card.description + ", ", terminator:"")}
            print()
        }
        for (i, cards) in tableau.enumerated() {
            print("tableau[\(i)]:")
            cards.forEach {card in print(card.description + ", ", terminator:"")}
            print()
        }
    }
    
    //
    // Find a card stack with 'card' on top
    //
    fileprivate func findCardStackWithCard(_ card : Card) -> CardStack? {
        if card == waste.last {
            return CardStack.waste
        } else if card == stock.last {
            return CardStack.stock
        } else {
            for i in 0 ..< 4 {
                if card == foundation[i].last {
                    return CardStack.foundation(i)
                }
            }
            for i in 0 ..< 7 {
                if card == tableau[i].last {
                    return CardStack.tableau(i)
                }
            }
        return nil
        }
    }
    
    fileprivate func findAndRemoveCardFromStack(_ card : Card) -> CardStack {
        let cardStack = findCardStackWithCard(card)!
        switch(cardStack) {
        case .waste:
            waste.removeLast()
        case .foundation(let index):
            foundation[index].removeLast()
        case .tableau(let index):
            tableau[index].removeLast()
        case .stock:
            stock.removeLast()
        }
        return cardStack
    }
    
    fileprivate func findAndRemoveCardFanFromStack(_ cards : [Card]) -> CardStack {
        let card = cards.last!
        let cardStack = findCardStackWithCard(card)!
        switch(cardStack) {
        case .foundation(let index):
            foundation[index].removeLast(cards.count)
        case .tableau(let index):
            tableau[index].removeLast(cards.count)
        default: break // shouldn't happen
        }
        return cardStack
    }
    
}







