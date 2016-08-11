import CoreLocation
import MapKit
import UIKit
import Toast_Swift
/*
 *  MeetingInfoViewController: Controller for meeting information view
 *  Connected by segue from SutdentListTableViewController.
 *  A staff and a user are passed in by segue.
 *  Connects to Firebase to query busRoute meeting information.
 */
class MeetingInfoTableViewController: UITableViewController, CLLocationManagerDelegate {
    
    // MARK: Properties
    var busRoutes = [BusRoute]()
    var students = [Student]()
    var staff:Staff!
    var parent:Parent!
    var isStaff:Bool!
    var locationManager:CLLocationManager!
    var locValue:CLLocation!
    var sharing:Bool = false
    var count = [Double!]()
    
    var meetingInfoWrapperList = [MeetingInfoWrapper]()
    
    // MARK: DbCommunicator
    var dbComm = DbCommunicator()
    
    // MARK: UIViewController Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.meetingInfoWrapperList = []
        loadData()
    }

    func loadData() {
        if (self.isStaff == true){
            self.locationManager = CLLocationManager()
            
            // For use in foreground
            self.locationManager.requestWhenInUseAuthorization()
            self.locationManager.requestAlwaysAuthorization()
            
            if CLLocationManager.locationServicesEnabled() {
                self.locationManager.delegate = self
                self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                self.locationManager.startUpdatingLocation()
            }
            
            dbComm.routeRef.queryOrderedByKey().queryEqualToValue(self.staff.routeID).observeEventType(.Value, withBlock: {   snapshot in
                var busRoutesFromDB = [BusRoute]()
                if (snapshot.hasChildren()){
                    for item in snapshot.children {
                        let routeFromDB = BusRoute(snapshot: item as! FIRDataSnapshot)
                        busRoutesFromDB.append(routeFromDB)
                    }
                }
                self.busRoutes = busRoutesFromDB
                self.tableView.reloadData()
            })
        } else {
            self.tableView.reloadData()
            for student in self.students {
                dbComm.routeRef.queryOrderedByKey().queryEqualToValue(student.routeID).observeEventType(.Value, withBlock: {
                    snapshot in
                    if (snapshot.hasChildren()){
                        for item in snapshot.children {
                            let routeFromDB = BusRoute(snapshot: item as! FIRDataSnapshot)
                            self.busRoutes.append(routeFromDB)
                            var studentID = student.key
                            self.dbComm.logRef.queryOrderedByKey().observeEventType(.Value, withBlock: {snapshot in
                                var res = 0.0
                                for datasnapshot in snapshot.children {
                                    if (datasnapshot.hasChild("afternoon") && datasnapshot.value!["afternoon"]!![studentID]! != nil) {
                                        res += datasnapshot.value!["afternoon"]!![studentID] as! Double
                                    }
                                    
                                    if (datasnapshot.hasChild("morning") && datasnapshot.value!["morning"]!![studentID]! != nil) {
                                        res += datasnapshot.value!["morning"]!![studentID] as! Double
                                    }
                                }
                                
                            })
                        self.meetingInfoWrapperList.append(MeetingInfoWrapper(student: student,busRoute: routeFromDB, count: 0.0))
                        }
                    }
                    self.tableView.reloadData()
                })
            }
        }
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locValue = locations[0]
        print("locations = \(locValue.coordinate.latitude) \(locValue.coordinate.longitude)")
        if (self.isStaff == true) {
            var currLocation: [String: Double] = ["Latitude": Double(locValue.coordinate.latitude), "Longitude": Double(locValue.coordinate.longitude)]
            dbComm.routeRef.child(self.staff.routeID).child("currLocation").updateChildValues(currLocation)
            dbComm.routeRef.child(self.staff.routeID).child("currLocation").child("current").setValue(true)
        }
    }
    

    @IBAction func locationDidPush(sender: AnyObject) {
        if (self.isStaff == true) {
            if (self.sharing == false) {
                self.view.makeToast("started sharing location", duration: 1.5, position: CGPoint(x:200.0, y:500.0))
                var currLocation: [String: Double] = ["Latitude": Double(locValue.coordinate.latitude), "Longitude": Double(locValue.coordinate.longitude)]
                dbComm.routeRef.child(self.staff.routeID).child("currLocation").updateChildValues(currLocation)
                dbComm.routeRef.child(self.staff.routeID).child("currLocation").child("current").setValue(true)
                self.sharing = true
            } else {
                self.view.makeToast("stopped sharing location", duration: 1.5, position: CGPoint(x:200.0, y:500.0))
                self.locationManager.stopUpdatingLocation()
                dbComm.routeRef.child(self.staff.routeID).child("currLocation").child("current").setValue(false)
            }
        } else {
            performSegueWithIdentifier("ParentMap", sender: self)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "ParentMap") {
            let nav = segue.destinationViewController as! MapsViewController
            nav.students = self.students
        }
    }

    
    // MARK: ViewDidAppear
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.meetingInfoWrapperList.removeAll()
    }

    // MARK: UITableView Delegate methods
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return busRoutes.count
    }
    
    // MARK: Display information depending on user type
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> MeetingInfoCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("MeetingInfoCell")! as! MeetingInfoCell
        
        if (self.isStaff == true){
            cell.infoOwnerLabel?.text = "Showing details for AcTran staff member: " + staff.name
            cell.meetingLocationLabel?.text = busRoutes[indexPath.row].meetingLocation
            cell.meetingTimeLabel?.text = busRoutes[indexPath.row].meetingTime
        }else{
            cell.infoOwnerLabel?.text = "Showing details for student: " + meetingInfoWrapperList[indexPath.row].student.name
            cell.meetingLocationLabel?.text = meetingInfoWrapperList[indexPath.row].busRoute.meetingLocation
            cell.meetingTimeLabel?.text = meetingInfoWrapperList[indexPath.row].busRoute.meetingTime
            let student : Student = meetingInfoWrapperList[indexPath.row].student
            cell.travelDistanceLabel?.text = "Total Distance Traveled: " + String(meetingInfoWrapperList[indexPath.row].count)
            
        }
        return cell
    }
    
//    func getDistance(studentID: String) -> Double {
//        self.dbComm.logRef.queryOrderedByKey().observeEventType(.Value, withBlock: {snapshot in
//            var res = 0.0
//            for datasnapshot in snapshot.children {
//                if (datasnapshot.hasChild("afternoon") && datasnapshot.value!["afternoon"]!![studentID]! != nil) {
//                    res += datasnapshot.value!["afternoon"]!![studentID] as! Double
//                }
//                
//                if (datasnapshot.hasChild("morning") && datasnapshot.value!["morning"]!![studentID]! != nil) {
//                    res += datasnapshot.value!["morning"]!![studentID] as! Double
//                }
//            }
//            self.count = res
//        })
//        print ("out" + String(self.count))
//        return self.count
//    }
}
