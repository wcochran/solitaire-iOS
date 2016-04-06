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
    var draggingFan : [CardLayer]? = nil  // fan of cards dragged
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
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        }
        draggingCardLayer!.position = position
        if let draggingFan = draggingFan {
            let off = FAN_OFFSET*draggingCardLayer!.bounds.size.height
            let n = draggingFan.count
            for i in 1 ..< n {
                let cardLayer = draggingFan[i]
                cardLayer.position = CGPointMake(position.x, position.y + CGFloat(i)*off)
            }
        }
        if !animate {
            CATransaction.commit()
        }
    }
}
