import Foundation
/**
 *  BusRoute Class
 *  Both students and staff store busRoutes that match them together
 */
import Firebase
struct BusRoute {
    let staffID: String
    let students: NSDictionary
    let meetingTime: String
    let meetingLocation: String
    let key: String
    
    // Initialize from Firebase Snapshot
    init(snapshot:FIRDataSnapshot) {
        staffID = snapshot.value!["staffID"] as! String
        students = snapshot.value!["students"] as! NSDictionary
        meetingTime = snapshot.value!["meetingTime"] as! String
        meetingLocation = snapshot.value!["meetingLocation"] as! String
        key = snapshot.key
    }
    
    // Initialize from arbitrary data
    init(staffID: String, students: NSDictionary, meetingTime: String, meetingLocation: String) {
        self.staffID = staffID
        self.students = students
        self.meetingTime = meetingTime
        self.meetingLocation = meetingLocation
        self.key = ""
    }
    
    // Convert to JSON object for pushing onto Firebase
    func toAnyObject() -> AnyObject {
        return[
            "staffID": staffID,
            "students": students,
            "meetingTime": meetingTime,
            "meetingLocation": meetingLocation
        ]
    }
    
}