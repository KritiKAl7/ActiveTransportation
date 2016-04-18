
import Foundation
/**
 *  MeetingInfoWrapper
 *  MeetingInfoWrapper class is locally created to populate the meetingInfoView cells.
 */
struct MeetingInfoWrapper {
    
    let student: Student!
    let busRoute: BusRoute!
    
    // Initialize from arbitrary data
    init(student: Student, busRoute: BusRoute) {
        self.student = student
        self.busRoute = busRoute
    }
}
