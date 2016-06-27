import Foundation
import Firebase
/**
 *  Staff
 *  Staff class extends User class.
 */
class Staff : User{
    var routeID:String
    
    // Initialize from arbitrary data
    init(key: String, name: String, email: String, contactInfo: String, isStaff: Bool, routeID: String) {
        self.routeID = routeID
        super.init(key: key, name: name, email: email, contactInfo: contactInfo, isStaff: isStaff)
    }
    
    // Initialize from Firebase snapshot data
    override
    init(snapshot:FIRDataSnapshot){
        // On intialization, staff may not have their route
        // assigned to them yet. In this case, set up an empty string
        self.routeID = ""
        if ((snapshot.value!.objectForKey("routeID")) != nil){
            self.routeID = snapshot.value!["routeID"] as! String
        }
        super.init(
            key:snapshot.key,
            name:snapshot.value!["name"] as! String,
            email:snapshot.value!["email"] as! String,
            contactInfo:snapshot.value!["contactInfo"] as! String,
            isStaff:snapshot.value!["isStaff"] as! Bool)
    }
    
    // Initialize from Firebase Authentication data
    override
    init(authData: FIRUser, name:String, contactInfo: String, isStaff: Bool) {
        self.routeID = ""
        super.init(key: authData.uid.lowercaseString,
                   name: name,
                   email:authData.email!,
                   contactInfo: contactInfo,
                   isStaff: true)
    }
    
    // Convert to JSON objects for pushing onto Firebase
    override
    func toAnyObject() -> AnyObject {
        return[
            "name": name,
            "email": email,
            "contactInfo": contactInfo,
            "isStaff": isStaff,
            "routeID":routeID
        ]
    }
}