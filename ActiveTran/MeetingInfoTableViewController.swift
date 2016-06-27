
import UIKit
/*
 *  MeetingInfoViewController: Controller for meeting information view
 *  Connected by segue from SutdentListTableViewController.
 *  A staff and a user are passed in by segue.
 *  Connects to Firebase to query busRoute meeting information.
 */
class MeetingInfoTableViewController: UITableViewController {
    
    // MARK: Properties
    var busRoutes = [BusRoute]()
    var students = [Student]()
    var staff:Staff!
    var parent:Parent!
    var isStaff:Bool!
    
    var meetingInfoWrapperList = [MeetingInfoWrapper]()
    
    // MARK: DbCommunicator
    var dbComm = DbCommunicator()
    
    // MARK: UIViewController Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        if (self.isStaff == true){
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
            for student in self.students {
                dbComm.routeRef.queryOrderedByKey().queryEqualToValue(student.routeID).observeEventType(.Value, withBlock: {
                    snapshot in
                    if (snapshot.hasChildren()){
                        for item in snapshot.children {
                            let routeFromDB = BusRoute(snapshot: item as! FIRDataSnapshot)
                            self.busRoutes.append(routeFromDB)
                            self.meetingInfoWrapperList.append(MeetingInfoWrapper(student: student,busRoute: routeFromDB))
                        }
                    }
                    self.tableView.reloadData()
                })
            }
        }
    }
    
    // MARK: ViewDidAppear
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
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
        }
        return cell
    }
}
