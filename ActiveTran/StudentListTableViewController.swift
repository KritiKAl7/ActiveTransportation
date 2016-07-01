
import UIKit
import MessageUI

class StudentListTableViewController: UITableViewController, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate {
    
    // MARK: Constants
    let ListToUsers = "ListToUsers"
    let ListToContactInfo = "ListToContactInfo"
    let ListToSettings = "ListToSettings"
    let Settings = "Settings"
    let MORNING_PERIOD = "morning"
    let AFTERNOON_PERIOD = "afternoon"
    
    // MARK: Data passed in from segue
    var contactInfoToPass: String!
    var nameToPass: String!
    var busRouteToPass: String!
    var isStaffToPass:Bool!
    var signUpMode = false
    var logExsits = false
    var isMorning = true
    var currentDate : String!
    var email: String!
    var password: String!
    var changed: Bool!
    var uid:String!
    var user:FIRUser!
    var auth:FIRAuth!
    
    // MARK: Selected student
    var studentSelected: StudentWrapper!
    
    // MARK: Properties
    var studentsWrapper = [String:StudentWrapper]()
    var students = [Student]()
    var keysForTable = [String]()
    var parent:Parent!
    var staff:Staff!
    var meetingInfoBarButtonItem: UIBarButtonItem!
    var settingsButtonItem: UIBarButtonItem!
    var isStaff = false
    var groupMessagePrep = 0
    
    
    // Mark: DbCommunicator
    var dbComm = DbCommunicator()
    
    
    override func viewDidLoad() {
        let date = NSDate()
        let calendar:NSCalendar = NSCalendar.currentCalendar()
        let components = calendar.components([.Hour], fromDate: date)
        let hour = components.hour
        
        if (hour > 0 && hour < 12){
            isMorning = true
        }else{
            isMorning = false
        }
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        self.currentDate =  dateFormatter.stringFromDate(date)
        if (isMorning == true){
            self.dbComm.currentLogRef = self.dbComm.currentLogRef.child(self.currentDate).child(MORNING_PERIOD)
        }else{
            self.dbComm.currentLogRef = self.dbComm.currentLogRef.child(self.currentDate).child(AFTERNOON_PERIOD)
        }
        
        // Set up swipe to delete
        tableView.allowsMultipleSelectionDuringEditing = false
        
        // meeting info display
        meetingInfoBarButtonItem = UIBarButtonItem(title: "Meeting Info", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("meetingInfoButtonDidTouch"))
        
        //TODO change font size
        meetingInfoBarButtonItem.tintColor = UIColor.whiteColor()
        navigationItem.leftBarButtonItem = meetingInfoBarButtonItem
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        self.authenticateUser()
        super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    // MARK: UITableView Delegate methods
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return studentsWrapper.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ItemCell")! as UITableViewCell
        let studentSelected = studentsWrapper[keysForTable[indexPath.row]]
        
        cell.textLabel?.text = studentSelected?.student.name
        cell.detailTextLabel?.text = "Student ID Number: " + (studentSelected?.student.key)!
        
        // Determine whether the cell is checked
        toggleCellCheckbox(cell, isCompleted: (studentSelected?.arrived)!)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let more = UITableViewRowAction(style: .Normal, title: "More") { (action, indexPath) in
            self.studentSelected = self.studentsWrapper[self.keysForTable[indexPath.row]]
            self.performSegueWithIdentifier(self.ListToContactInfo, sender: nil)
        }
        
        more.backgroundColor = UIColor.grayColor()
        return [more]
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // Find the cell that user tapped using cellForRowAtIndexPath
        let cell = tableView.cellForRowAtIndexPath(indexPath)!
        // Get the corresponding GreoceryItem by using the index path's row
        let studentSelected = self.studentsWrapper[self.keysForTable[indexPath.row]]
        
        // Staff Only: Negate completed on the student to toggle the status
        // Only staff has editing access
        if (self.isStaff == true){
            let toggleCompletion = !studentSelected!.arrived
            // Call toggleCellCheckbox() update the visual properties of the cell
            toggleCellCheckbox(cell, isCompleted: toggleCompletion)
            // Passing a dictioary to update Firebase
            self.dbComm.currentLogRef.updateChildValues([studentSelected!.student.key : toggleCompletion])
            
        }
    }
    
    
    func toggleCellCheckbox(cell: UITableViewCell, isCompleted: Bool) {
        if !isCompleted {
            cell.accessoryType = UITableViewCellAccessoryType.None
            cell.textLabel?.textColor = UIColor.blackColor()
            cell.detailTextLabel?.textColor = UIColor.blackColor()
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            cell.textLabel?.textColor = UIColor.grayColor()
            cell.detailTextLabel?.textColor = UIColor.grayColor()
        }
    }
    @IBAction func settingsDidTouch(sender: AnyObject) {
        performSegueWithIdentifier(self.ListToSettings, sender: nil)
    }
    // MARK: Add Item
    // Button to email or group message page
    @IBAction func emailButtonDidTouch(sender: AnyObject) {
        
        let alertTitle = "Notify All"
        let alertMessage = "Who do you wish to notify?"
        
        // show an alert and ask whether to call the parent/staff or not
        let alert = UIAlertController(title: alertTitle,
                                      message: alertMessage ,
                                      preferredStyle: .Alert)
        
        let groupMessageAction = UIAlertAction(title: "Send Text Message To All", style: .Default) { (action: UIAlertAction)
            -> Void in
            // get an array of parent's phone numbers, then send group message
            var phoneNum = [String]()
            if (self.isStaff == true){
                for s in self.students{
                    self.dbComm.usersRef.child(s.parentID).observeSingleEventOfType(.Value, withBlock: {
                        snapshot in
                        if (snapshot.hasChildren()){
                            let parent = Parent(snapshot:snapshot)
                            if (!phoneNum.contains(parent.contactInfo)){
                                phoneNum.append(parent.contactInfo)
                            }
                        }
                        // Async function call helper
                        self.groupMessagePrep += 1
                        if (self.groupMessagePrep == self.students.count-1){
                            self.operation(phoneNum)
                            // reset
                            self.groupMessagePrep = 0
                        }
                    })
                }
            }else {
                for s in self.students{
                    self.dbComm.routeRef.child(s.routeID).observeSingleEventOfType(.Value, withBlock: {
                        snapshot in
                        if (snapshot.hasChildren()){
                            let staffID = snapshot.value!["staffID"] as! String
                            self.dbComm.usersRef.child(staffID).observeEventType(.Value, withBlock: {
                                snapshot2 in
                                if(snapshot2.hasChildren()){
                                    let staff = Staff(snapshot:snapshot2)
                                    if (!phoneNum.contains(staff.contactInfo)){
                                        phoneNum.append(staff.contactInfo)
                                    }
                                }
                                // Async function call helper
                                self.groupMessagePrep += 1
                                if (self.groupMessagePrep == self.students.count-1){
                                    self.operation(phoneNum)
                                    // reset
                                    self.groupMessagePrep = 0
                                }
                            })
                        }
                    })
                }
            }
        }
        
        let emailAction = UIAlertAction(title: "Send Email To School Admin", style: .Default) { (action: UIAlertAction) -> Void in
            let mailComposeViewController = self.configuredMailComposeViewController()
            if MFMailComposeViewController.canSendMail(){
                self.presentViewController(mailComposeViewController, animated: true, completion: nil)
            } else {
                self.showSendMailErrorAlert()
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .Default) { (action: UIAlertAction) -> Void in
        }
        
        alert.addAction(groupMessageAction)
        alert.addAction(emailAction)
        alert.addAction(cancelAction)
        
        presentViewController(alert,
                              animated: true,
                              completion: nil)
    }
    
    func showSendMailErrorAlert(){
        let sendMailErrorAlert = UIAlertView(title:"Could Not Send Email", message:"Your device could not send e-mail.  Please check e-mail configuration and try again.", delegate: self, cancelButtonTitle: "OK")
        sendMailErrorAlert.show()
    }
    
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        mailComposerVC.setToRecipients(["someone@somewhere.com"])
        mailComposerVC.setSubject("Active Transportation Bus Route")
        mailComposerVC.setMessageBody("Sending e-mail in-app is not so bad!", isHTML: false)
        
        return mailComposerVC
    }
    
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func meetingInfoButtonDidTouch() {
        performSegueWithIdentifier(self.ListToUsers, sender: nil)
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "ListToUsers") {
            let nav = segue.destinationViewController as! MeetingInfoTableViewController
            nav.isStaff = self.isStaff
            if (self.isStaff == true){
                if (self.staff != nil){
                    nav.staff = self.staff
                    nav.students = self.students
                }
            } else {
                if (self.parent != nil){
                    nav.parent = self.parent
                    nav.students = self.students
                }
            }
        } else if (segue.identifier == "ListToContactInfo") {
            let nav = segue.destinationViewController as! ContactInfoViewController
            if (self.isStaff == true){
                if (self.staff != nil) {
                    nav.isStaff = true
                    nav.studentWprSelected = self.studentSelected
                    nav.staff = self.staff
                }
            }else {
                if (self.parent != nil){
                    nav.isStaff = false
                    nav.studentWprSelected = self.studentSelected
                    nav.parent = self.parent
                }
                
            }
        } else if (segue.identifier == "ListToSettings") {
            let nav = segue.destinationViewController as! SettingsViewController
            nav.email = self.email
            nav.password = self.password
            nav.user = self.user
            nav.auth = self.auth
        }
    }
    
    func authenticateUser(){
        FIRAuth.auth()?.addAuthStateDidChangeListener() {
            (auth, user) in
            if user != nil {
                if (self.signUpMode == true){
                    let currentUserRef = self.dbComm.usersRef.child(user!.uid)
                    self.uid = user!.uid
                    if (self.isStaff){
                        self.staff = Staff(authData: user!, name:self.nameToPass, contactInfo:self.contactInfoToPass,
                            isStaff:true)
                        currentUserRef.setValue(self.staff.toAnyObject())
                    } else {
                        self.parent = Parent(authData: user!, name:self.nameToPass, contactInfo:self.contactInfoToPass,
                            isStaff:false)
                        currentUserRef.setValue(self.parent.toAnyObject())
                    }
                    try! FIRAuth.auth()!.signOut()
                    self.reloadTable()
                    self.nullDataAlert()
                } else{
                    let idCopy = user!.uid
                    print(idCopy)
                    self.dbComm.usersRef.child(idCopy).observeEventType(.Value, withBlock: { snapshot in
                        if (snapshot.hasChildren()){
                            if (snapshot.value!["isStaff"] as! Bool){
                                self.isStaff = true
                                self.staff = Staff(snapshot: snapshot)
                            }else{
                                self.isStaff = false
                                self.parent = Parent(snapshot: snapshot)
                            }
                        }
                        self.loadStudentInfo()
                    })
                    // need this to switch between accounts
                    // try! FIRAuth.auth()!.signOut()
                }
            }
        }
        
        
        
        
//        self.dbComm.rootRef.observeAuthEventWithBlock { authData in
//            if authData != nil {
//                if (self.signUpMode == true){
//                    let currentUserRef = Firebase!(self.dbComm.usersRef.childByAppendingPath(authData.uid))
//                    self.uid = authData.uid
//                    if (self.isStaff){
//                        self.staff = Staff(authData:authData, name:self.nameToPass, contactInfo:self.contactInfoToPass,
//                            isStaff:true)
//                        currentUserRef.setValue(self.staff.toAnyObject())
//                    } else {
//                        self.parent = Parent(authData:authData, name:self.nameToPass, contactInfo:self.contactInfoToPass,
//                            isStaff:false)
//                        currentUserRef.setValue(self.parent.toAnyObject())
//                    }
//                    self.dbComm.rootRef.unauth()
//                    self.reloadTable()
//                    self.nullDataAlert()
//                } else{
//                    let idCopy = authData.uid.lowercaseString
//                    self.dbComm.usersRef.childByAppendingPath(idCopy).observeEventType(.Value, withBlock: { snapshot in
//                        if (snapshot.hasChildren()){
//                            if (snapshot.value["isStaff"] as! Bool){
//                                self.isStaff = true
//                                self.staff = Staff(snapshot: snapshot)
//                            }else{
//                                self.isStaff = false
//                                self.parent = Parent(snapshot: snapshot)
//                            }
//                        }
//                        self.loadStudentInfo()
//                    })
//                    // need this to switch between accounts
//                    self.dbComm.rootRef.unauth()
//                }
//            }
//        }
    }
    
    func loadStudentInfo(){
        if(self.isStaff && self.staff.routeID != ""){
            self.dbComm.routeRef.child(self.staff.routeID).observeEventType(.Value, withBlock: {
                snapshot in
                if (snapshot.hasChildren()){
                    let item = BusRoute(snapshot: snapshot as FIRDataSnapshot)
                    for s in item.students{
                        self.keysForTable.append(s.key as! String)
                        // go find actual student object
                        self.dbComm.studentsRef.child(s.key as! String).observeEventType(.Value, withBlock: {
                            snapshot2 in
                            if (snapshot2.hasChildren()){
                                let newStudent = Student(snapshot: snapshot2 as FIRDataSnapshot)
                                let newStudentWpr = StudentWrapper(student: newStudent, arrived: false)
                                self.students.append(newStudent)
                                self.studentsWrapper[newStudent.key] = newStudentWpr
                            }
                            // go find log
                            self.loadStudentArvInfo(s.key as! String);
                        })
                    }
                } else {
                    self.nullDataAlert()
                }
            })
        } else if(!self.isStaff && self.parent.childrenIDs.count > 0){
            self.dbComm.usersRef.child(self.parent.key).child("childrenIDs").observeEventType(.Value,withBlock:{
                snapshot in
                if (snapshot.hasChildren()){
                    let childrenIDs = snapshot.value as! NSDictionary
                    // each child is saved as a ID:name pair in childrenIDs
                    for child in childrenIDs {
                        // save the children's key (studentID) in the keysForTable array
                        // for later display purposes
                        self.keysForTable.append(child.key as! String)
                        // go fetch the actual Student object
                        self.dbComm.studentsRef.child(child.key as! String).observeEventType(.Value,withBlock:{
                            snapshot2 in
                            if (snapshot2.hasChildren()){
                                let newStudent = Student(snapshot: snapshot2 as FIRDataSnapshot)
                                let newStudentWpr = StudentWrapper(student:newStudent,arrived:false)
                                self.students.append(newStudent)
                                self.studentsWrapper[newStudent.key] = newStudentWpr
                            }
                            self.loadStudentArvInfo(child.key as! String)
                        })
                    }
                } else {
                    self.nullDataAlert()
                }
            })
        }else{
            self.nullDataAlert()
        }
    }
    
    
    func nullDataAlert(){
        let alertTitle = "No record found"
        var alertMessage = ""
        if (self.isStaff){
            alertMessage = "No assigned route record for \(self.staff.name) is found. Contact system admin for details."
        } else {
            alertMessage = "No children record for \(self.parent.name) is found. Contact system admin for details."
        }
        
        // show an alert and ask whether to call the parent/staff or not
        let alert = UIAlertController(title: alertTitle,
                                      message: alertMessage ,
                                      preferredStyle: .Alert)
        
        let okAction = UIAlertAction(title: "OK",
                                     style: .Default) { (action: UIAlertAction) -> Void in
        }
        
        alert.addAction(okAction)
        
        self.presentViewController(alert, animated: true,completion: nil)
    }
    
    func groupMessageFailureAlert(){
        let alertTitle = "Group Message Failure"
        var alertMessage = "Unable to send group message, please check for errors in contact information."
        
        // show an alert and ask whether to call the parent/staff or not
        let alert = UIAlertController(title: alertTitle,
                                      message: alertMessage ,
                                      preferredStyle: .Alert)
        
        let okAction = UIAlertAction(title: "OK",
                                     style: .Default) { (action: UIAlertAction) -> Void in
        }
        
        alert.addAction(okAction)
        
        self.presentViewController(alert, animated: true,completion: nil)
    }
    
    func loadStudentArvInfo(studentID: String){
        if (self.isStaff){
            // For staff, create new log records for the day
            self.dbComm.currentLogRef.observeEventType(.Value, withBlock: {
                snapshot in
                // If the staff is the first one logging in on that day,
                // or if the log for that particular student hasn't been created yet
                if (!snapshot.exists() || snapshot.value!.objectForKey(studentID) == nil){
                    self.dbComm.currentLogRef.updateChildValues([studentID : false])
                    self.studentsWrapper[studentID]!.arrived = false
                }else{
                    self.studentsWrapper[studentID]!.arrived = snapshot.value![studentID] as! Bool
                }
                self.logExsits = true
                self.reloadTable()
            })
        } else {
            self.dbComm.currentLogRef.child(studentID).observeEventType(.Value,withBlock: {
                snapshot in
                if (snapshot.value is NSNull){
                    self.logExsits = false
                } else {
                    self.studentsWrapper[studentID]!.arrived = snapshot.value as! Bool
                    self.logExsits = true
                }
                self.reloadTable()
            })
        }
    }
    
    func reloadTable(){
        self.tableView.reloadData()
    }
    
    // MARK: Function for carrying out the group messaging operations
    private func operation(phoneNumber:[String]) {
        var phoneNumberOpSafe = checkPhoneNumber(phoneNumber)
        if (phoneNumberOpSafe.count>0){
            let alert = UIAlertController(title: "Sending Group Text Message",
                                          message: "Please enter the text message content below." ,
                                          preferredStyle: .Alert)
            
            let sendAction = UIAlertAction(title: "Send", style: .Default) { (action: UIAlertAction) -> Void in
                // Get the text field from the alert controller
                let textField = alert.textFields![0]
                
                if MFMessageComposeViewController.canSendText(){
                    let msg:MFMessageComposeViewController=MFMessageComposeViewController()
                    msg.recipients=phoneNumberOpSafe
                    msg.body=textField.text
                    msg.messageComposeDelegate = self
                    self.presentViewController(msg,animated:true,completion:nil)
                } else {
                    print ("Sending group text message failed")
                }
            }
            let cancelAction = UIAlertAction(title: "Cancel",
                                             style: .Default) { (action: UIAlertAction) -> Void in
            }
            
            alert.addTextFieldWithConfigurationHandler {
                (textField: UITextField!) -> Void in
            }
            alert.addAction(sendAction)
            alert.addAction(cancelAction)
            
            presentViewController(alert,
                                  animated: true,
                                  completion: nil)
            
        }else{
            self.groupMessageFailureAlert()
        }
    }
    
    private func checkPhoneNumber(phoneNum:[String]) -> [String]{
        var temp = phoneNum
        for index in 0...phoneNum.count-1{
            var valid = true
            for c in phoneNum[index].characters{
                if (!(c >= "0" && c <= "9")) {
                    valid = false
                    break
                }
            }
            if (valid == false){
                temp.removeAtIndex(index)
            }
        }
        return temp
    }
    
    // MARK
    func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult){
        switch result.rawValue {
        case MessageComposeResultCancelled.rawValue:
            controller.dismissViewControllerAnimated(true, completion: nil)
        case MessageComposeResultFailed.rawValue:
            controller.dismissViewControllerAnimated(true, completion: nil)
        case MessageComposeResultSent.rawValue:
            controller.dismissViewControllerAnimated(false, completion: nil)
            
        default:
            break
        }
    }
    

}