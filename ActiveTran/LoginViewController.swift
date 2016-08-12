import UIKit
import QuartzCore
import Toast_Swift
/**
 *  LoginViewController: Controller for user login and registering.
 *  First View the user encounters.
 *  Segues to StudentListTableViewController.
 *  Login View Controller manages the login and registering functions.
 *
 */
class LoginViewController: UIViewController {
    
    // MARK: Flag for segue identifier
    let LoginToList = "LoginToList"
    let ChangeToSettings = "ChangeToSettings"
    var signUpMode = false
    
    // MARK: Data passed through Segue to StudentListTableView
    var contactInfoToPass: String!
    var nameToPass: String!
    var routeIDToPass: String!
    var isStaffToPass:Bool!
    var email: String!
    var password: String!
    var currUser: FIRUser!
    var auth: FIRAuth!
    
    // Mark: Communicator with Firebase
    var dbComm = DbCommunicator()
    
    // MARK: Outlets
    @IBOutlet weak var textFieldLoginEmail: UITextField!
    @IBOutlet weak var textFieldLoginPassword: UITextField!
    override func viewDidLoad() {
        self.navigationItem.hidesBackButton = true
    }
    // MARK: UIViewController Lifecycle
    override func viewDidAppear(animated: Bool) {
        
        signUpMode = false
        try! FIRAuth.auth()!.signOut()
        // Create an authentication observer
        FIRAuth.auth()!.addAuthStateDidChangeListener() {
            (auth, user) in
            if let user = user {
                print("user signed in with uid: ", user.uid)
                self.currUser = user
                self.auth = auth
            } else {
                print("No user")
            }
        }
    }
    
    
    // MARK: Actions
//    @IBAction func loginDidTouch(sender: AnyObject) {
//        dbComm.rootRef.authUser(textFieldLoginEmail.text, password: textFieldLoginPassword.text,
//                                withCompletionBlock: { (error, auth) in
//                                    
//        })
//    }
    @IBAction func loginDidTouch(sender: AnyObject) {
        FIRAuth.auth()!.signInWithEmail(textFieldLoginEmail.text!, password: textFieldLoginPassword.text!) { (user, error) in
            if let error = error {
                print("Sign in failed:", error)
                self.view.makeToast(error.localizedDescription)
            } else {
                self.currUser = user
                self.dbComm.usersRef.child(user!.uid).observeEventType(.Value, withBlock: {
                    snapshot in
                    if (snapshot.hasChild("passwordChanged") && !(snapshot.value!["passwordChanged"] as! Bool)) {
                        let alert = UIAlertController(title: "Change your password", message: "Welcome! Please change from default password", preferredStyle: .Alert)
                        let saveAction = UIAlertAction(title: "OK", style: .Default)
                        { (action: UIAlertAction) -> Void in
                            self.performSegueWithIdentifier(self.ChangeToSettings, sender: nil)
                        }
                        let cancelAction = UIAlertAction(title: "Cancel",
                        style: .Default) { (action: UIAlertAction) -> Void in
                        }
                        
                        alert.addAction(saveAction)
                        alert.addAction(cancelAction)
                        
                        self.presentViewController(alert,
                            animated: true,
                            completion: nil)
                    } else {
                        print ("Signed in with uid:", user!.uid)
                        self.performSegueWithIdentifier(self.LoginToList, sender: nil)
                    }
                })
                
                
            }
        }
    }
    
    // MARK: Actions
    @IBAction func signUpDidTouch(sender: AnyObject) {
        let alert = UIAlertController(title: "Sign Up",
                                      message: "Sign Up for Active Transporation",
                                      preferredStyle: .Alert)
        
        let saveAction = UIAlertAction(title: "Save",
                                       style: .Default)
        { (action: UIAlertAction) -> Void in
            let emailField = alert.textFields![0]
            if (self.textFieldLoginEmail.text?.isEmpty != true){
                emailField.text = self.textFieldLoginEmail.text
            }
            let passwordField = alert.textFields![1]
            let nameField = alert.textFields![2]
            let contactInfoField = alert.textFields![3]
            let isStaffField = alert.textFields![4]
            
            self.nameToPass = nameField.text
            self.contactInfoToPass = contactInfoField.text
            self.isStaffToPass = (isStaffField.text?.lowercaseString.containsString("yes"))
            
//            self.dbComm.studentsRef.createUser(emailField.text, password: passwordField.text) { (error: NSError!) in
//                if error == nil {
//                    self.dbComm.rootRef.authUser(emailField.text, password: passwordField.text,
//                                                 withCompletionBlock: { (error, auth) -> Void in
//                                                    self.performSegueWithIdentifier(self.LoginToList, sender: nil)
//                    })
//                self.email = emailField.text
//                self.password = passwordField.text
//                }
//            }
            FIRAuth.auth()?.createUserWithEmail(emailField.text!, password: passwordField.text!) { (user, error) in
                if error == nil {
                    FIRAuth.auth()?.signInWithEmail(emailField.text!, password: passwordField.text!){
                        (error, auth) -> Void in
                        self.signUpMode = true
                        self.performSegueWithIdentifier(self.LoginToList, sender: nil)
                    }
                    self.email = emailField.text
                    self.password = passwordField.text
                }
            }

        }
        
        
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .Default) { (action: UIAlertAction) -> Void in
                                           self.signUpMode = false
        }
        
        alert.addTextFieldWithConfigurationHandler {
            (textEmail) -> Void in
            textEmail.placeholder = "Enter your email"
        }
        
        alert.addTextFieldWithConfigurationHandler {
            (textPassword) -> Void in
            textPassword.secureTextEntry = true
            textPassword.placeholder = "Enter your password"
        }
        
        alert.addTextFieldWithConfigurationHandler {
            (textName) -> Void in
            textName.placeholder = "Enter your name"
        }
        
        alert.addTextFieldWithConfigurationHandler {
            (textInfo) -> Void in
            textInfo.placeholder = "Enter your contact information"
        }
        
        alert.addTextFieldWithConfigurationHandler {
            (textInfo) -> Void in
            textInfo.placeholder = "Enter Yes if Staff, No if Parent"
        }
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        presentViewController(alert,
                              animated: true,
                              completion: nil)
    }
    
    @IBAction func forgetPasswordDidTouch(sender: AnyObject) {
        NSOperationQueue.mainQueue().addOperationWithBlock() {
            let userEmail = self.textFieldLoginEmail.text
            if (userEmail!.isEmpty != true){
                FIRAuth.auth()?.sendPasswordResetWithEmail(userEmail!) {
                    error in
                    if let error = error{
                        NSOperationQueue.mainQueue().addOperationWithBlock() {
                        self.view.makeToast(error.localizedDescription)
                        }
                    } else {
                        NSOperationQueue.mainQueue().addOperationWithBlock() {
                        self.view.makeToast("Password reset Email sent, please check your inbox ")
                        }
                    }
                }
            } else {
                self.view.makeToast("Please enter your Email to reset Password")
            }
        }
    }
    // Segue to StudentListTableViewController
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "LoginToList") {
            print ("segue called")
            let nav = segue.destinationViewController as! UINavigationController
            let svc = nav.topViewController as! StudentListTableViewController
            if (self.signUpMode == true){
                svc.nameToPass = self.nameToPass
                svc.contactInfoToPass = self.contactInfoToPass
                svc.busRouteToPass = self.routeIDToPass
                svc.isStaff = self.isStaffToPass
                svc.signUpMode = self.signUpMode
            }
            svc.email = self.email
            svc.password = self.password
            svc.changed = false
            svc.user = self.currUser
            svc.auth = self.auth
            
        }
        if (segue.identifier == "ChangeToSettings") {
            print ("segue called")
            let nav = segue.destinationViewController as! SettingsViewController
            nav.email = self.email
            nav.password = self.password
            nav.user = self.currUser
            nav.auth = self.auth
            nav.secure = false
        }
    }

}