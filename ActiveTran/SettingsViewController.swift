//
//  SettingsViewController.swift
//  ActiveTransportation
//
//  Created by cssummer16 on 6/22/16.
//
//

import Foundation
import UIKit
import Toast_Swift

class SettingsViewController: UIViewController{
    
    let ListToChecklist = "ListToChecklist"
    
    var email: String!
    var password: String!
    var changed = false
    var uid: String!
    var user:FIRUser!
    var auth:FIRAuth!
    var secure: Bool!
    var newpassword: String!
    
    var screenwidth : CGFloat!
    var screenheight : CGFloat!
    
    var toastPoint : CGPoint!
    
    var dbComm = DbCommunicator()
    
    override func viewDidAppear(animated: Bool) {
        
        // Create an authentication observer
        FIRAuth.auth()!.addAuthStateDidChangeListener() {
            (auth, user) in
            if let user = user {
                print("user signed in with uid: ", user.uid)
            } else {
                print("No user")
            }
        }
    }
    
    override func viewDidLoad() {
        print ("userid:"+self.user.uid)
        self.screenwidth = self.view.frame.size.width
        self.screenheight = self.view.frame.size.height
        self.toastPoint = CGPoint(x: self.screenwidth / 2, y: self.screenheight / 2 + 190)
        print (self.toastPoint)
    }
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
//        let nav = segue.destinationViewController as! StudentListTableViewController
//    }
    
    @IBAction func changePhone(sender: AnyObject) {
        let alert = UIAlertController(title: "Change Phone Number", message: "Change your phone number", preferredStyle: .Alert)
        let saveAction = UIAlertAction(title: "Save", style: .Default)
        { (action: UIAlertAction) -> Void in
            let phoneField = alert.textFields![0]
            self.dbComm.usersRef.child(self.user.uid).child("contactInfo").setValue(phoneField.text)
        }
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .Default) { (action: UIAlertAction) -> Void in
        }
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        alert.addTextFieldWithConfigurationHandler {
            (textName) -> Void in
            textName.placeholder = "Enter new phone number"
        }
        
        presentViewController(alert,
                              animated: true,
                              completion: nil)
    }
    
    @IBAction func changeEmail(sender: AnyObject) {
        let alert = UIAlertController(title: "Change Email", message: "Change your Email address", preferredStyle: .Alert)
        let saveAction = UIAlertAction(title: "Save", style: .Default)
        { (action: UIAlertAction) -> Void in
            let email = alert.textFields![0]
            
            let user = FIRAuth.auth()?.currentUser
            
            user?.updateEmail(email.text!) { error in
                if let error = error {
                    // An error happened.
                    self.view.makeToast(error.localizedDescription)
                } else {
                    // Email updated.
                    self.view.makeToast("Email changed")
                    self.dbComm.usersRef.child(self.user.uid).child("email").setValue(email.text)
                }
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .Default) { (action: UIAlertAction) -> Void in
        }
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        alert.addTextFieldWithConfigurationHandler {
            (textName) -> Void in
            textName.placeholder = "Enter new email address"
        }
        
        presentViewController(alert,
                              animated: true,
                              completion: nil)

    }
    
    @IBAction func logOut(sender: AnyObject) {
        try! FIRAuth.auth()!.signOut()
        print ("signed out user: " + self.user.uid)
    }
    
    @IBAction func changePassword(sender: AnyObject) {
        let alert = UIAlertController(title: "Change Password", message: "Change your password", preferredStyle: .Alert)
        let saveAction = UIAlertAction(title: "Save", style: .Default)
        { (action: UIAlertAction) -> Void in
            let password = alert.textFields![0]
            let repassword = alert.textFields![1]
            if (password.text != repassword.text) {
                self.view.makeToast("Please make sure the two passwords are the same")
            } else {
                let user = FIRAuth.auth()?.currentUser
                user?.updatePassword(password.text!) {
                    error in
                    if let error = error {
                        self.view.makeToast("Change Failed:" + error.localizedDescription, duration: 3.0, position: self.toastPoint)
                    } else {
                        self.view.makeToast("Changed password",duration: 3.0, position: self.toastPoint)
                        if (self.secure != nil && !self.secure) {
                            self.dbComm.usersRef.child(self.user.uid).child("passwordChanged").setValue(true)
                            self.newpassword = password.text
                            self.performSegueWithIdentifier(self.ListToChecklist, sender: nil)
                        }
                    }
                }
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .Default) { (action: UIAlertAction) -> Void in
        }
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        alert.addTextFieldWithConfigurationHandler {
            (textPassword) -> Void in
            textPassword.secureTextEntry = true
            textPassword.placeholder = "New Password"
        }
        alert.addTextFieldWithConfigurationHandler {
            (textPassword) -> Void in
            textPassword.secureTextEntry = true
            textPassword.placeholder = "Re-enter new password"
        }
        presentViewController(alert,
                              animated: true,
                              completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "ListToChecklist") {
            let nav = segue.destinationViewController as! UINavigationController
            let svc = nav.topViewController as! StudentListTableViewController
            svc.email = self.email
            svc.password = self.newpassword
            svc.user = self.user
            svc.auth = self.auth
        }
    }
    
}