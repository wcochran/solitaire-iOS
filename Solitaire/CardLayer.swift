//
//  CardLayer.swift
//  Solitaire
//
//  Created by Wayne Cochran on 4/4/16.
//  Copyright © 2016 Wayne Cochran. All rights reserved.
//

import UIKit

class CardLayer: CALayer {
    let card : Card
    var faceUp : Bool
    
    init(card : Card) {
        self.card = card
        faceUp = true
        super.init()
    }
    
    //
    // This is only needed when a CardLayer is deserialized
    // out of a NIB, which should never happen in this app.
    // http://www.edwardhuynh.com/blog/2015/02/16/swift-initializer-confusion/
    //
    required init?(coder aDecoder: NSCoder) {
        card = Card(suit: Suit.SPADES, rank: ACE)
        faceUp = true
        super.init(coder: aDecoder)
    }
    
}
