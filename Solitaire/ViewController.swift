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
        
//        if let undoManager = undoManager { // never true?
//            undoBarButtonItem.enabled = undoManager.canUndo
//            redoBarButtonItem.enabled = undoManager.canRedo
//        }
        
        undoBarButtonItem.isEnabled = false
        redoBarButtonItem.isEnabled = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.undoManagerCheckpoint(_:)), name: NSNotification.Name.NSUndoManagerCheckpoint, object: nil)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func redeal(_ sender: AnyObject) {
        let alert = UIAlertController(title: "New Game?", message: "Redeal cards?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Redeal", style: .destructive, handler: {
            [unowned self] action in
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.solitaire.freshGame()
            self.solitaireView.collectAllCardsInStock()
            self.solitaireView.layoutCards()
            self.undoManager?.removeAllActions() // does *not* trigger NSUndoManagerCheckpointNotification
            self.undoBarButtonItem.isEnabled = false
            self.redoBarButtonItem.isEnabled = false
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @IBOutlet weak var undoBarButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var redoBarButtonItem: UIBarButtonItem!
    
    @objc func undoManagerCheckpoint(_ notification : Notification) {
        if let undoManager = undoManager {
            undoBarButtonItem.isEnabled = undoManager.canUndo
            redoBarButtonItem.isEnabled = undoManager.canRedo
        }
    }
    
    @IBAction func undo(_ sender: AnyObject) {
        undoManager?.undo()
    }
    
    @IBAction func redo(_ sender: AnyObject) {
        undoManager?.redo()
    }
    
}

