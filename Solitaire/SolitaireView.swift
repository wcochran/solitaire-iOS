//
//  SolitaireView.swift
//  Solitaire
//
//  Created by Wayne Cochran on 4/5/16.
//  Copyright © 2016 Wayne Cochran. All rights reserved.
//

import UIKit

let CARDASPECT : CGFloat = 150.0/215.0
let FAN_OFFSET : CGFloat = 0.15

class SolitaireView: UIView {

    var stockLayer : CALayer!
    var wasteLayer : CALayer!
    var foundationLayers : [CALayer]!
    var tableauLayers : [CALayer]!
    
    var topZPosition : CGFloat = 0
    var cardToLayerDictionary : [Card : CardLayer]!
    
    var draggingCardLayer : CardLayer? = nil // card layer dragged (nil => no drag)
    var draggingFan : [Card]? = nil  // fan of cards dragged
    var touchStartPoint : CGPoint = CGPoint.zero
    var touchStartLayerPosition : CGPoint = CGPoint.zero
    
    lazy var solitaire : Solitaire!  = { // reference to model in app delegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.solitaire
    }()
    let numberOfCardsToDeal = 3
    
    override func awakeFromNib() {
        self.layer.name = "background"
        
        stockLayer = CALayer()
        stockLayer.name = "stock"
        stockLayer.backgroundColor = UIColor(colorLiteralRed: 0.0, green: 0.5, blue: 0.0, alpha: 0.3).cgColor
        self.layer.addSublayer(stockLayer)
        
        wasteLayer = CALayer()
        wasteLayer.name = "waste"
        wasteLayer.backgroundColor = UIColor(colorLiteralRed: 0.0, green: 0.5, blue: 0.0, alpha: 0.3).cgColor
        self.layer.addSublayer(wasteLayer)
        
        let foundationColor = UIColor(colorLiteralRed: 0.0, green: 0.0, blue: 0.5, alpha: 0.3)
        foundationLayers = []
        for i in 0 ..< 4 {
            let foundationLayer = CALayer();
            foundationLayer.name = "foundation \(i)"
            foundationLayer.backgroundColor = foundationColor.cgColor
            self.layer.addSublayer(foundationLayer)
            foundationLayers.append(foundationLayer)
        }
        
        let tableauColor = UIColor(colorLiteralRed: 0.0, green: 0.0, blue: 0.5, alpha: 0.3)
        tableauLayers = []
        for i in 0 ..< 7 {
            let tableauLayer = CALayer();
            tableauLayer.name = "tableau \(i)"
            tableauLayer.backgroundColor = tableauColor.cgColor
            self.layer.addSublayer(tableauLayer)
            tableauLayers.append(tableauLayer)
        }

        let deck = Card.deck()
        cardToLayerDictionary = [:]
        for card in deck {
            let cardLayer = CardLayer(card: card)
            cardLayer.name = "card"
            self.layer.addSublayer(cardLayer)
            cardToLayerDictionary[card] = cardLayer
        }
        
        becomeFirstResponder() // for shake -> triggers undo
    }
    
    override var canBecomeFirstResponder : Bool {
        return true // for shake -> triggers undo
    }
    
    func layoutTableAndCards() {
        let width = bounds.size.width
        let height = bounds.size.height
        let portrait = width < height
        
        let horzMargin = portrait ? 0.0325*width : 0.03125*width
        let vertMargin = portrait ? 0.026*height : 0.039*height
        let cardSpacing = portrait ? 0.0195*width : 0.026*width
        let tableauSpacing = portrait ? 0.0417*height : 0.026*height
        
        let cardWidth = (width - 2*horzMargin - 6*cardSpacing)/7
        let cardHeight = cardWidth / CARDASPECT
        
        stockLayer.frame = CGRect(x: horzMargin, y: vertMargin, width: cardWidth, height: cardHeight)
        wasteLayer.frame = CGRect(x: horzMargin + cardSpacing + cardWidth, y: vertMargin, width: cardWidth, height: cardHeight)
        
        var x = width - horzMargin - cardWidth
        for i in (0...3).reversed() {
            foundationLayers[i].frame = CGRect(x: x, y: vertMargin, width: cardWidth, height: cardHeight)
            x -= cardSpacing + cardWidth
        }
        
        x = horzMargin
        let y = vertMargin + cardHeight + tableauSpacing
        for i in 0 ..< 7 {
            tableauLayers[i].frame = CGRect(x: x, y: y, width: cardWidth, height: cardHeight)
            x += cardSpacing + cardWidth
        }
        
        layoutCards()
    }
    
    func layoutCards() {
        var z : CGFloat = 1.0
        
        let stock = solitaire.stock
        for card in stock {
            let cardLayer = cardToLayerDictionary[card]!
            cardLayer.frame = stockLayer.frame
            cardLayer.faceUp = solitaire.isCardFaceUp(card)
            cardLayer.zPosition = z
            z = z + 1
        }
        
        let waste = solitaire.waste
        for card in waste {
            let cardLayer = cardToLayerDictionary[card]!
            cardLayer.frame = wasteLayer.frame
            cardLayer.faceUp = solitaire.isCardFaceUp(card)
            cardLayer.zPosition = z
            z = z + 1
        }
        
        for i in 0 ..< 4 {
            let foundation = solitaire.foundation[i]
            for card in foundation {
                let cardLayer = cardToLayerDictionary[card]!
                cardLayer.frame = foundationLayers[i].frame
                cardLayer.faceUp = solitaire.isCardFaceUp(card)
                cardLayer.zPosition = z
                z = z + 1
            }
        }
        
        let cardSize = stockLayer.bounds.size
        let fanOffset = FAN_OFFSET * cardSize.height
        for i in 0 ..< 7 {
            let tableau = solitaire.tableau[i]
            let tableauOrigin = tableauLayers[i].frame.origin
            var j : CGFloat = 0
            for card in tableau {
                let cardLayer = cardToLayerDictionary[card]!
                cardLayer.frame = CGRect(x: tableauOrigin.x, y: tableauOrigin.y + j*fanOffset, width: cardSize.width, height: cardSize.height)
                cardLayer.faceUp = solitaire.isCardFaceUp(card)
                cardLayer.zPosition = z
                z = z + 1
                j = j + 1
            }
        }
        
        topZPosition = z
    }
    
    
    override func layoutSublayers(of layer: CALayer) {
        draggingCardLayer = nil // deactivate any dragging
        layoutTableAndCards()
    }
    
    func collectAllCardsInStock() {
        var z : CGFloat = 1
        for card in cardToLayerDictionary.keys {
            let cardLayer = cardToLayerDictionary[card]!
            cardLayer.faceUp = false
            cardLayer.frame = stockLayer.frame
            cardLayer.zPosition = z
            z = z + 1
        }
        draggingCardLayer = nil
        topZPosition = z
    }
    
    //
    // Used to move a 'fan' of card from one tableau to another.
    //
    func moveCardsToPosition(_ cards: [Card], position : CGPoint, animate : Bool) {
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for card in cards {
            let cardLayer = cardToLayerDictionary[card]!
            cardLayer.zPosition = topZPosition
            topZPosition = topZPosition + 1
        }
        CATransaction.commit()
        
        if !animate {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
        }
        
        var off : CGFloat = 0
        for card in cards {
            let cardLayer = cardToLayerDictionary[card]!
            cardLayer.position = CGPoint(x: position.x, y: position.y + off)
            off += FAN_OFFSET*cardLayer.bounds.height
        }
        if !animate {
            CATransaction.commit()
        }
    }
    
    //
    // Used while user is dragging cards around.
    // Uses current 'draggingCardLayer' and 'draggingFan' variables.
    // z-positions should already be above all other card layers.
    //
    func dragCardsToPosition(_ position : CGPoint, animate : Bool) {
        if !animate {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
        }
        draggingCardLayer!.position = position
        if let draggingFan = draggingFan {
            let off = FAN_OFFSET*draggingCardLayer!.bounds.size.height
            let n = draggingFan.count
            for i in 1 ..< n {
                let card = draggingFan[i]
                let cardLayer = cardToLayerDictionary[card]!
                cardLayer.position = CGPoint(x: position.x, y: position.y + CGFloat(i)*off)
            }
        }
        if !animate {
            CATransaction.commit()
        }
    }
    
    func moveCardLayerToTop(_ cardLayer : CardLayer) {
        CATransaction.begin()  // do not animate z-position change
        CATransaction.setDisableActions(true)
        cardLayer.zPosition = topZPosition
        topZPosition = topZPosition + 1
        CATransaction.commit()
    }
    
  func animateDeal( _ cardLayers : [CardLayer]) {
    var cardLayers = cardLayers
    if cardLayers.count > 0 {
            let cardLayer = cardLayers[0]
            cardLayers.remove(at: 0)
            
            moveCardLayerToTop(cardLayer)
            
            CATransaction.begin()
            CATransaction.setCompletionBlock {
                self.animateDeal(cardLayers)
            }
            CATransaction.setAnimationDuration(0.25)
            cardLayer.faceUp = true
            cardLayer.position = wasteLayer.position
            CATransaction.commit()
        }
    }
    
    func multiCardDeal() {
        let cards = solitaire.dealCards(numberOfCardsToDeal)
        
        undoManager?.registerUndo(withTarget: self, handler: { me in
            me.undoMultiCard(cards)
        })
        undoManager?.setActionName("deal cards")
        
        var cardLayers : [CardLayer] = []
        for c in cards {
            let clayer = cardToLayerDictionary[c]!
            cardLayers.append(clayer)
        }
        animateDeal(cardLayers)
    }
    
    func undoMultiCard(_ cards : [Card]) {
        undoManager?.registerUndo(withTarget: self, handler: { me in
            me.multiCardDeal()
        })
        undoManager?.setActionName("deal cards")
        
        self.solitaire.undoDealCards(cards.count)
        self.layoutCards()
    }
    
    func oneCardDeal() {
        undoManager?.registerUndo(withTarget: self, handler: {me in
            me.undoOneCardDeal()
        })
        undoManager?.setActionName("deal card")
        
        let card = solitaire.stock.last!
        let cardLayer = cardToLayerDictionary[card]!
        moveCardLayerToTop(cardLayer)
        cardLayer.position = wasteLayer.position
        cardLayer.faceUp = true
        solitaire.didDealCard()
    }
    
    func undoOneCardDeal() {
        undoManager?.registerUndo(withTarget: self, handler: {me in
            me.oneCardDeal()
        })
        undoManager?.setActionName("deal card")
        
        self.solitaire.undoDealCard()
        self.layoutCards()
    }
    
    func flipCard(_ card : Card, faceUp up : Bool) {
        undoManager?.registerUndo(withTarget: self, handler: {me in
            me.flipCard(card, faceUp: !up)
        })
        undoManager?.setActionName("flip card")
        
        let cardLayer = cardToLayerDictionary[card]
        cardLayer!.faceUp = up
        up ? solitaire.didFlipCard(card) : solitaire.undoFlipCard(card)
    }
    
    func collectWasteCardsIntoStock() {
        undoManager?.registerUndo(withTarget: self, handler: {me in
            me.undoCollectWasteCardsIntoStock()
        })
        undoManager?.setActionName("collect waste cards")
        
        solitaire.collectWasteCardsIntoStock()
        var z : CGFloat = 1
        for card in solitaire.stock {
            let cardLayer = cardToLayerDictionary[card]!
            cardLayer.faceUp = false
            cardLayer.frame = stockLayer.frame
            cardLayer.zPosition = z
            z = z + 1
        }
    }
    
    func undoCollectWasteCardsIntoStock() {
        undoManager?.registerUndo(withTarget: self, handler: {me in
            me.collectWasteCardsIntoStock()
        })
        undoManager?.setActionName("collect waste cards")
        
        solitaire.undoCollectWasteCardsIntoStock()
        layoutCards()
    }
    
    
    func dropCard(_ card : Card, onFoundation i : Int) {
        let cardLayer = cardToLayerDictionary[card]!
        moveCardLayerToTop(cardLayer)
        cardLayer.position = foundationLayers[i].position
        let cardStack = solitaire.didDropCard(card, onFoundation: i)

        undoManager?.registerUndo(withTarget: self, handler: {me in
            me.undoDropCard(card, fromStack: cardStack, onFoundation: i)
        })
        undoManager?.setActionName("drop card on foundation")
    }
    
    func undoDropCard(_ card: Card, fromStack source: CardStack, onFoundation i : Int) {
        solitaire.undoDidDropCard(card, fromStack: source, onFoundation: i)
        layoutCards()
        
        undoManager?.registerUndo(withTarget: self, handler: { me in
            me.dropCard(card, onFoundation: i)
        })
        undoManager?.setActionName("drop card on foundation")
    }

    func dropCard(_ card : Card, onTableau i : Int) {
        let cardLayer = cardToLayerDictionary[card]!
        let stackCount = solitaire.tableau[i].count
        let cardHeight = cardLayer.bounds.height
        let fanOffset = FAN_OFFSET*cardHeight
        moveCardLayerToTop(cardLayer)
        cardLayer.position = CGPoint(x: tableauLayers[i].position.x, y: tableauLayers[i].position.y + CGFloat(stackCount)*fanOffset)
        let cardStack = solitaire.didDropCard(card, onTableau: i)
        
        undoManager?.registerUndo(withTarget: self, handler: {me in
            me.undoDropCard(card, fromStack: cardStack, onTableau: i)
        })
        undoManager?.setActionName("drop card on tableau")
    }
    
    func undoDropCard(_ card: Card, fromStack source: CardStack, onTableau i : Int) {
        solitaire.undoDidDropCard(card, fromStack: source, onTableau: i)
        layoutCards()
        
        undoManager?.registerUndo(withTarget: self, handler: { me in
            me.dropCard(card, onTableau: i)
        })
        undoManager?.setActionName("drop card on tableau")
    }
    
    func dropFan(_ cards : [Card], onTableau i : Int) {
        let card = cards.first!
        let cardLayer = cardToLayerDictionary[card]!
        let stackCount = solitaire.tableau[i].count
        let cardHeight = cardLayer.bounds.height
        let fanOffset = FAN_OFFSET*cardHeight
        let position = CGPoint(x: tableauLayers[i].position.x, y: tableauLayers[i].position.y + CGFloat(stackCount)*fanOffset)
        moveCardsToPosition(cards, position: position, animate: true)
        let cardStack = solitaire.didDropFan(cards, onTableau: i)
        
        undoManager?.registerUndo(withTarget: self, handler: { me in
            me.undoDropFan(cards, fromStack: cardStack, onTableau: i)
        })
        undoManager?.setActionName("drag fan")
    }
    
    func undoDropFan(_ cards : [Card], fromStack source: CardStack, onTableau i : Int) {
        solitaire.undoDidDropFan(cards, fromStack: source, onTableau: i)
        layoutCards()
        
        undoManager?.registerUndo(withTarget: self, handler: { me in
            me.dropFan(cards, onTableau: i) // XXX redo blow up
        })
        undoManager?.setActionName("drag fan")
    }

    
    //
    // Note: the point passed to hitTest: is in the coordinate system of
    // self.layer.superlayer
    // http://goo.gl/FIzjZD
    //
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let touchPoint = touch.location(in: self)
        let hitTestPoint = self.layer.convert(touchPoint, to: self.layer.superlayer)
        let layer = self.layer.hitTest(hitTestPoint)
        
        if let layer = layer {
            if layer.name == "card" {
                let cardLayer = layer as! CardLayer
                let card = cardLayer.card
                if solitaire.isCardFaceUp(card) {
                    touchStartPoint = touchPoint
                    touchStartLayerPosition = cardLayer.position
                    CATransaction.begin()  // do not animate z-position change
                    CATransaction.setDisableActions(true)
                    cardLayer.zPosition = topZPosition
                    topZPosition = topZPosition + 1
                    draggingFan = solitaire.fanBeginningWithCard(card)
                    if let draggingFan = draggingFan {
                        for i in 1 ..< draggingFan.count {
                            let card = draggingFan[i]
                            let clayer = cardToLayerDictionary[card]!
                            clayer.zPosition = topZPosition
                            topZPosition = topZPosition + 1
                        }
                    }
                    CATransaction.commit()
                    
                    if touch.tapCount > 1 {
                        if draggingFan == nil || draggingFan!.count <= 1 {
                            for i in 0 ..< 4 {
                                if solitaire.canDropCard(card, onFoundation: i) {
                                    dropCard(card, onFoundation: i)
                                    break;
                                }
                            }
                        }
                        return
                    }
                    
                    draggingCardLayer = cardLayer
                } else if solitaire.canFlipCard(card) {
                    flipCard(card, faceUp: true)
                } else if solitaire.stock.last == card {
                    if numberOfCardsToDeal > 1 {
                        multiCardDeal()
                    } else {
                        oneCardDeal()
                    }
                }
            } else if (layer.name == "stock") {
                collectWasteCardsIntoStock()
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if draggingCardLayer != nil {
            let touch = touches.first!
            let p = touch.location(in: self)
            let delta = CGPoint(x: p.x - touchStartPoint.x, y: p.y - touchStartPoint.y)
            let position = CGPoint(x: touchStartLayerPosition.x + delta.x,
                                       y: touchStartLayerPosition.y + delta.y)
            dragCardsToPosition(position, animate: false)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if draggingCardLayer != nil {
            dragCardsToPosition(touchStartLayerPosition, animate: true)
            draggingCardLayer = nil
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let dragLayer = draggingCardLayer {
            let numCards = draggingFan == nil ? 1 : draggingFan!.count
            
            if numCards == 1 { // drop on foundation or tableau
                //
                // Drop card on foundation?
                //
                for i in 0 ..< 4 {
                    if dragLayer.frame.intersects(foundationLayers[i].frame) && solitaire.canDropCard(dragLayer.card, onFoundation: i) {
                        dropCard(dragLayer.card, onFoundation: i)
                        draggingCardLayer = nil
                        return // done
                    }
                }
                
                //
                // Drop card on tableau?
                //
                for i in 0 ..< 7 {
                    let topCard = solitaire.tableau[i].isEmpty ? nil : solitaire.tableau[i].last
                    var targetFrame : CGRect
                    if let topCard = topCard {
                        let topCardLayer = cardToLayerDictionary[topCard]!
                        targetFrame = topCardLayer.frame
                    } else {
                        targetFrame = tableauLayers[i].frame
                    }
                    if dragLayer.frame.intersects(targetFrame) && solitaire.canDropCard(dragLayer.card, onTableau: i) {
                        if topCard != nil {
                            let cardSize = targetFrame.size
                            let fanOffset = FAN_OFFSET*cardSize.height
                            targetFrame.origin.y += fanOffset
                        }
                        dropCard(dragLayer.card, onTableau: i)
                        draggingCardLayer = nil
                        return // done
                    }
                }
                
            }  // end numCards == 1
            
            //
            // Drop fan of cards on tableau?
            //
            if let fan = draggingFan {
                for i in 0 ..< 7 {
                    let topCard = solitaire.tableau[i].isEmpty ? nil : solitaire.tableau[i].last
                    var topCardLayer : CardLayer? = nil
                    var targetFrame : CGRect
                    if let topCard = topCard {
                        topCardLayer = cardToLayerDictionary[topCard]
                        targetFrame = topCardLayer!.frame
                    } else {
                        targetFrame = tableauLayers[i].frame
                    }
                    if dragLayer.frame.intersects(targetFrame) && solitaire.canDropFan(fan, onTableau: i) {
                        dropFan(fan, onTableau: i)
                        draggingCardLayer = nil
                        return // done
                    }
                }
            }
            
            //
            // Didn't drop any cards ... move 'em back to original position
            //
            dragCardsToPosition(touchStartLayerPosition, animate: true)
            draggingCardLayer = nil
        }
    }
}
