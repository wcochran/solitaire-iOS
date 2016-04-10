//
//  ViewController.swift
//  Solitaire
//
//  Created by Wayne Cochran on 4/3/16.
//  Copyright © 2016 Wayne Cochran. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var solitaireView: SolitaireView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        if let undoManager = undoManager {
            undoBarButtonItem.enabled = undoManager.canUndo
            redoBarButtonItem.enabled = undoManager.canRedo
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func redeal(sender: AnyObject) {
        let alert = UIAlertController(title: "New Game?", message: "Redeal cards?", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Redeal", style: .Destructive, handler: { action in
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.solitaire.freshGame()
            self.solitaireView.collectAllCardsInStock()
            self.solitaireView.layoutCards()
            self.undoManager?.removeAllActions()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func undoManagerCheckpoint(notification : NSNotification) {
        NSLog("undoManagerCheckpoint")
        
    }

    @IBOutlet weak var undoBarButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var redoBarButtonItem: UIBarButtonItem!
    
    
    @IBAction func undo(sender: AnyObject) {
    }
    
    @IBAction func redo(sender: AnyObject) {
    }
    
}

