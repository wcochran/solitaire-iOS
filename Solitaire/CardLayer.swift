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
    let imageName = "\(suits[Int(card.suit.rawValue)])-\(ranks[Int(card.rank)])-150.png"
    let image = UIImage(named: imageName)!
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
    static let backImage = UIImage(named: "back-blue-150-1.png")
    
    init(card : Card) {
        self.card = card
        faceUp = true
        frontImage = imageForCard(card)
        super.init()
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
