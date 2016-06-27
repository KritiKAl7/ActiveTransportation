import Foundation
/**
 *  User
 *  User class is extended by both Staff and Parent classes.
 */
import Firebase
class User {
    var key: String
    let name: String
    let email: String
    let contactInfo: String
    let isStaff: Bool!

    // Initialize from Firebase Authentication data
    init(authData: FIRUser, name:String, contactInfo: String, isStaff: Bool) {
        self.key = authData.uid.lowercaseString
        self.name = name
        self.email = authData.email!
        self.contactInfo = contactInfo
        self.isStaff = isStaff 
    }
    
    // Initialize from Firebase snapshot data
    init(snapshot: FIRDataSnapshot) {
        key = snapshot.key
        name = snapshot.value!["name"] as! String
        email = snapshot.value!["email"] as! String
        contactInfo = snapshot.value!["contactInfo"] as! String
        isStaff = snapshot.value!["isStaff"] as! Bool
        
    }
  
    // Initialize from arbitrary data
    init(key: String, name: String, email: String, contactInfo: String, isStaff: Bool) {
        self.key = key
        self.name = name
        self.email = email
        self.contactInfo = contactInfo
        self.isStaff = isStaff
    }
    
    // Convert to JSON object for pushing onto Firebase
    func toAnyObject() -> AnyObject {
        return[
            "name": name,
            "email": email,
            "contactInfo": contactInfo,
            "isStaff": isStaff
            ]
    }
}
