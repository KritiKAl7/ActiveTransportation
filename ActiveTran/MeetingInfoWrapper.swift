
import Foundation
/**
 *  MeetingInfoWrapper
 *  MeetingInfoWrapper class is locally created to populate the meetingInfoView cells.
 */
struct MeetingInfoWrapper {
    
    let student: Student!
    let busRoute: BusRoute!
    let count: Double!
    
    // Initialize from arbitrary data
    init(student: Student, busRoute: BusRoute, count: Double) {
        self.student = student
        self.busRoute = busRoute
        self.count = count
    }
}
