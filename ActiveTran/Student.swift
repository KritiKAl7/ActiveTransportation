import Foundation
/**
 * Student Class
 */
import Firebase
struct Student {
    
    let key: String!
    let name: String!
    let parentID : String!
    let routeID: String!
    let school: String!
  
    
    // Initialization from given data
    init(name: String, studentID: String, school: String, key: String = "", parentID : String, staffID : String, routeID: String) {
        self.key = key
        self.name = name
        self.school = school
        self.parentID = parentID;
        self.routeID = routeID;
  }
    
    // Initialization from Firebase snapshot data
    init(snapshot: FIRDataSnapshot) {
        key = snapshot.key
        name = snapshot.value!["name"] as! String
        school = snapshot.value!["school"] as! String
        parentID = snapshot.value!["parentID"] as! String
        routeID = snapshot.value!["routeID"] as! String
    }
    
    // Convert to JSON object for pushing onto Firebase
    func toAnyObject() -> AnyObject {
        return [
          "name": name,
          "school": school,
          "parentID": parentID,
          "routeID": routeID,
        ]
    }
}
