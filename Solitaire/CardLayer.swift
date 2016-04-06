//
//  CardLayer.swift
//  Solitaire
//
//  Created by Wayne Cochran on 4/4/16.
//  Copyright © 2016 Wayne Cochran. All rights reserved.
//

import UIKit

func imageForCard(card : Card) -> UIImage {
    let suits = [
        "spades", "clubs", "diamonds", "hearts"
    ]
    let ranks = [
        "", "a", "2", "3", "4", "5", "6", "7", "8", "9", "10", "j", "q", "k"
    ]
    let imageName = "150/\(suits[Int(card.suit.rawValue)])-\(ranks[Int(card.rank)])-150.png"
    let image = UIImage(named: imageName, inBundle: nil, compatibleWithTraitCollection: nil)!
    return image
}

class CardLayer: CALayer {
    let card : Card
    var faceUp : Bool {
        didSet {
            if faceUp != oldValue {
                let image = faceUp ? frontImage : CardLayer.backImage
                self.contents = image?.CGImage
            }
        }
    }
    let frontImage : UIImage
    static let backImage = UIImage(named: "150/back-blue-150-1.png", inBundle: nil, compatibleWithTraitCollection: nil)
    
    init(card : Card) {
        self.card = card
        faceUp = true
        frontImage = imageForCard(card)
        super.init()
        self.contents = frontImage.CGImage
        self.contentsGravity = kCAGravityResizeAspect
    }
    
    //
    // This initializer is used to create shadow copies of layers, 
    // for example, for the presentationLayer method.
    // See the docs:
    //  https://developer.apple.com/library/mac/documentation/GraphicsImaging/Reference/CALayer_class/#//apple_ref/occ/instm/CALayer/initWithLayer:
    //
    override init(layer: AnyObject) {
        if let layer = layer as? CardLayer {
            card = layer.card
            faceUp = layer.faceUp
            frontImage = layer.frontImage
        } else {
            card = Card(suit: Suit.SPADES, rank: ACE)
            faceUp = true
            frontImage = imageForCard(card)
        }
        super.init(layer: layer)
        self.contents = frontImage.CGImage
        self.contentsGravity = kCAGravityResizeAspect
    }
    
    //
    // This is only needed when a CardLayer is deserialized
    // out of a NIB, which should never happen in this app.
    // http://www.edwardhuynh.com/blog/2015/02/16/swift-initializer-confusion/
    //
    required init?(coder aDecoder: NSCoder) {
        card = Card(suit: Suit.SPADES, rank: ACE)
        faceUp = true
        frontImage = imageForCard(card)
        super.init(coder: aDecoder)
    }
    
}
