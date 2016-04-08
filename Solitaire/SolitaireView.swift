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
    var touchStartPoint : CGPoint = CGPointZero
    var touchStartLayerPosition : CGPoint = CGPointZero
    
    lazy var solitaire : Solitaire!  = { // reference to model in app delegate
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return appDelegate.solitaire
    }()
    let numberOfCardsToDeal = 3
    
    override func awakeFromNib() {
        self.layer.name = "background"
        
        stockLayer = CALayer()
        stockLayer.name = "stock"
        stockLayer.backgroundColor = UIColor(colorLiteralRed: 0.0, green: 0.5, blue: 0.0, alpha: 0.3).CGColor
        self.layer.addSublayer(stockLayer)
        
        wasteLayer = CALayer()
        wasteLayer.name = "waste"
        wasteLayer.backgroundColor = UIColor(colorLiteralRed: 0.0, green: 0.5, blue: 0.0, alpha: 0.3).CGColor
        self.layer.addSublayer(wasteLayer)
        
        let foundationColor = UIColor(colorLiteralRed: 0.0, green: 0.0, blue: 0.5, alpha: 0.3)
        foundationLayers = []
        for i in 0 ..< 4 {
            let foundationLayer = CALayer();
            foundationLayer.name = "foundation \(i)"
            foundationLayer.backgroundColor = foundationColor.CGColor
            self.layer.addSublayer(foundationLayer)
            foundationLayers.append(foundationLayer)
        }
        
        let tableauColor = UIColor(colorLiteralRed: 0.0, green: 0.0, blue: 0.5, alpha: 0.3)
        tableauLayers = []
        for i in 0 ..< 7 {
            let tableauLayer = CALayer();
            tableauLayer.name = "tableau \(i)"
            tableauLayer.backgroundColor = tableauColor.CGColor
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
    
    override func canBecomeFirstResponder() -> Bool {
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
        
        stockLayer.frame = CGRectMake(horzMargin, vertMargin, cardWidth, cardHeight)
        wasteLayer.frame = CGRectMake(horzMargin + cardSpacing + cardWidth, vertMargin, cardWidth, cardHeight)
        
        var x = width - horzMargin - cardWidth
        for i in (0...3).reverse() {
            foundationLayers[i].frame = CGRectMake(x, vertMargin, cardWidth, cardHeight)
            x -= cardSpacing + cardWidth
        }
        
        x = horzMargin
        let y = vertMargin + cardHeight + tableauSpacing
        for i in 0 ..< 7 {
            tableauLayers[i].frame = CGRectMake(x, y, cardWidth, cardHeight)
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
            cardLayer.zPosition = z++
        }
        
        let waste = solitaire.waste
        for card in waste {
            let cardLayer = cardToLayerDictionary[card]!
            cardLayer.frame = wasteLayer.frame
            cardLayer.faceUp = solitaire.isCardFaceUp(card)
            cardLayer.zPosition = z++
        }
        
        for i in 0 ..< 4 {
            let foundation = solitaire.foundation[i]
            for card in foundation {
                let cardLayer = cardToLayerDictionary[card]!
                cardLayer.frame = foundationLayers[i].frame
                cardLayer.faceUp = solitaire.isCardFaceUp(card)
                cardLayer.zPosition = z++
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
                cardLayer.frame = CGRectMake(tableauOrigin.x, tableauOrigin.y + j*fanOffset, cardSize.width, cardSize.height)
                cardLayer.faceUp = solitaire.isCardFaceUp(card)
                cardLayer.zPosition = z++
                j++
            }
        }
        
        topZPosition = z
    }
    
    override func layoutSublayersOfLayer(layer: CALayer) {
        draggingCardLayer = nil // deactivate any dragging
        layoutTableAndCards()
    }
    
    func collectAllCardsInStock() {
        var z : CGFloat = 1
        for card in cardToLayerDictionary.keys {
            let cardLayer = cardToLayerDictionary[card]!
            cardLayer.faceUp = false
            cardLayer.frame = stockLayer.frame
            cardLayer.zPosition = z++
        }
        draggingCardLayer = nil
        topZPosition = z
    }
    
    func dragCardsToPosition(position : CGPoint, animate : Bool) {
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
                cardLayer.position = CGPointMake(position.x, position.y + CGFloat(i)*off)
            }
        }
        if !animate {
            CATransaction.commit()
        }
    }
    
    func moveCardLayerToTop(cardLayer : CardLayer) {
        CATransaction.begin()  // do not animate z-position change
        CATransaction.setDisableActions(true)
        cardLayer.zPosition = topZPosition++
        CATransaction.commit()
    }
    
    func animateDeal(inout cardLayers : [CardLayer]) {
        if cardLayers.count > 0 {
            let cardLayer = cardLayers[0]
            cardLayers.removeAtIndex(0)
            
            moveCardLayerToTop(cardLayer)
            
            CATransaction.begin()
            CATransaction.setCompletionBlock {
                self.animateDeal(&cardLayers)
            }
            CATransaction.setAnimationDuration(0.25)
            cardLayer.faceUp = true
            cardLayer.position = wasteLayer.position
            CATransaction.commit()
        }
    }
    
    func multiCardDeal() {
        let cards = solitaire.dealCards(numberOfCardsToDeal)
        
        undoManager?.registerUndoWithTarget(self, handler: { me in
            me.undoMultiCard(cards)
        })
        undoManager?.setActionName("deal cards")
        
        var cardLayers : [CardLayer] = []
        for c in cards {
            let clayer = cardToLayerDictionary[c]!
            cardLayers.append(clayer)
        }
        animateDeal(&cardLayers)
    }
    
    func undoMultiCard(cards : [Card]) {
        undoManager?.registerUndoWithTarget(self, handler: { me in
            me.multiCardDeal()
        })
        undoManager?.setActionName("deal cards")
        
        self.solitaire.undoDealCards(cards.count)
        self.layoutCards()
    }
    
    func oneCardDeal() {
        undoManager?.registerUndoWithTarget(self, handler: {me in
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
        undoManager?.registerUndoWithTarget(self, handler: {me in
            me.oneCardDeal()
        })
        undoManager?.setActionName("deal card")
        
        self.solitaire.undoDealCard()
        self.layoutCards()
    }
    
    func flipCard(card : Card, faceUp up : Bool) {
        undoManager?.registerUndoWithTarget(self, handler: {me in
            me.flipCard(card, faceUp: !up)
        })
        undoManager?.setActionName("flip card")
        
        let cardLayer = cardToLayerDictionary[card]
        cardLayer!.faceUp = up
        if (up) {
            solitaire.didFlipCard(card)
        } else {
            solitaire.undoFlipCard(card)
        }
    }
    
    func collectWasteCardsIntoStock() {
        undoManager?.registerUndoWithTarget(self, handler: {me in
            me.undoCollectWasteCardsIntoStock()
        })
        undoManager?.setActionName("collect waste cards")
        
        solitaire.collectWasteCardsIntoStock()
        var z : CGFloat = 1
        for card in solitaire.stock {
            let cardLayer = cardToLayerDictionary[card]!
            cardLayer.faceUp = false
            cardLayer.frame = stockLayer.frame
            cardLayer.zPosition = z++
        }
    }
    
    func undoCollectWasteCardsIntoStock() {
        undoManager?.registerUndoWithTarget(self, handler: {me in
            me.collectWasteCardsIntoStock()
        })
        undoManager?.setActionName("collect waste cards")
        
        solitaire.undoCollectWasteCardsIntoStock()
        layoutCards() // XXX could do this fancier
    }
    
    //
    // XXX
    // The current model for undoing dropping cards on stack
    // isn't going to work.
    //
    
//    func tryMovingCardToFoundation(card : Card) {
//        var srcStack : [Card]? = nil
//        var foundationIndex = 0
//        for i in 0 ..< 4 {
//            if solitaire.canDropCard(card, onFoundation: i) {
//                let cardLayer = cardToLayerDictionary[card]!
//                cardLayer.zPosition = topZPosition++
//                cardLayer.position = foundationLayers[i].position
//                srcStack = solitaire.didDropCard(card, onFoundation: i)
//                foundationIndex = 0
//                break;
//            }
//        }
//        if let srcStack = srcStack {
//            undoManager?.registerUndoWithTarget(self, handler: { me in
//                me.moveCard(card, fromStack: &srcStack, toFoundation: foundationIndex)
//            })
//            undoManager?.setActionName("move card to foundation")
//        }
//    }
    
    func moveCard(card : Card, inout fromStack src : [Card], toFoundation i : Int) {
        solitaire.undoDidDropCard(card, byMovingItFromStack: &src, toStack: &solitaire.foundation[i])
    }
    
    //
    // Note: the point passed to hitTest: is in the coordinate system of
    // self.layer.superlayer
    // http://goo.gl/FIzjZD
    //
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touch = touches.first!
        let touchPoint = touch.locationInView(self)
        let hitTestPoint = self.layer.convertPoint(touchPoint, toLayer: self.layer.superlayer)
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
                    cardLayer.zPosition = topZPosition++
                    draggingFan = solitaire.fanBeginningWithCard(card)
                    if let draggingFan = draggingFan {
                        for i in 1 ..< draggingFan.count {
                            let card = draggingFan[i]
                            let clayer = cardToLayerDictionary[card]!
                            clayer.zPosition = topZPosition++
                        }
                    }
                    CATransaction.commit()
                    
                    if touch.tapCount > 1 {
                        if draggingFan == nil || draggingFan!.count <= 1 {
                            for i in 0 ..< 4 {
                                if solitaire.canDropCard(card, onFoundation: i) {
                                    cardLayer.zPosition = topZPosition++
                                    cardLayer.position = foundationLayers[i].position
                                    solitaire.didDropCard(card, onFoundation: i)
                                    undoManager?.removeAllActions() // XXX not undoable for now
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
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if draggingCardLayer != nil {
            let touch = touches.first!
            let p = touch.locationInView(self)
            let delta = CGPointMake(p.x - touchStartPoint.x, p.y - touchStartPoint.y)
            let position = CGPointMake(touchStartLayerPosition.x + delta.x,
                                       touchStartLayerPosition.y + delta.y)
            dragCardsToPosition(position, animate: false)
        }
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        if draggingCardLayer != nil {
            dragCardsToPosition(touchStartLayerPosition, animate: true)
            draggingCardLayer = nil
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let dragLayer = draggingCardLayer {
            let numCards = draggingFan == nil ? 1 : draggingFan!.count
            
            if numCards == 1 { // drop on foundation or tableau
                
                //
                // Drop card on foundation?
                //
                for i in 0 ..< 4 {
                    if CGRectIntersectsRect(dragLayer.frame, foundationLayers[i].frame) && solitaire.canDropCard(dragLayer.card, onFoundation: i) {
                        draggingCardLayer!.frame = foundationLayers[i].frame
                        solitaire.didDropCard(dragLayer.card, onFoundation: i)
                        draggingCardLayer = nil
                        undoManager?.removeAllActions() // XXX not undoable for now
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
                    if CGRectIntersectsRect(dragLayer.frame, targetFrame) && solitaire.canDropCard(dragLayer.card, onTableau: i) {
                        if topCard != nil {
                            let cardSize = targetFrame.size
                            let fanOffset = FAN_OFFSET*cardSize.height
                            targetFrame.origin.y += fanOffset
                        }
                        draggingCardLayer!.frame = targetFrame
                        solitaire.didDropCard(dragLayer.card, onTableau: i)
                        draggingCardLayer = nil
                        undoManager?.removeAllActions() // XXX not undoable for now
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
                    if CGRectIntersectsRect(dragLayer.frame, targetFrame) && solitaire.canDropFan(fan, onTableau: i) {
                        let position : CGPoint
                        if topCard != nil {
                            let cardSize = targetFrame.size
                            let fanOffset = FAN_OFFSET*cardSize.height
                            position = CGPointMake(topCardLayer!.position.x, topCardLayer!.position.y + fanOffset)
                        } else {
                            position = tableauLayers[i].position
                        }
                        dragCardsToPosition(position, animate: true)
                        solitaire.didDropFan(fan, onTableau: i)
                        draggingCardLayer = nil
                        undoManager?.removeAllActions() // XXX not undoable for now
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
