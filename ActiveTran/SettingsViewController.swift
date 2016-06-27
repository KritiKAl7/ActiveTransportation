//
//  SettingsViewController.swift
//  ActiveTransportation
//
//  Created by cssummer16 on 6/22/16.
//
//

import Foundation
import UIKit

class SettingsViewController: UITableViewController {
    var email: String!
    var password: String!
    var changed = false
    var uid: String!
    
    var dbComm = DbCommunicator()
    
    
    override func viewDidLoad() {
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        let nav = segue.destinationViewController as! StudentListTableViewController
    }
    
    @IBAction func changePhone(sender: AnyObject) {
        let alert = UIAlertController(title: "Change Phone Number", message: "Change Phone Number", preferredStyle: .Alert)
        let saveAction = UIAlertAction(title: "Save", style: .Default)
        { (action: UIAlertAction) -> Void in
            let phoneField = alert.textFields![0]
            self.dbComm.usersRef.child(self.uid).child("contactInfo").setValue(phoneField.text)
        }
    }
    
}