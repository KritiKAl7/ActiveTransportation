import Foundation
import Firebase
/**
 *  Parent
 *  Staff class extends User class.
 */
class Parent : User{

    var childrenIDs:NSDictionary
    
    // Initialize from arbitrary data
    init(key: String, name: String, email: String, contactInfo: String, isStaff: Bool, childrenIDs: NSDictionary) {
        self.childrenIDs = childrenIDs
        super.init(key: key, name: name, email: email, contactInfo: contactInfo, isStaff: isStaff)
    }
    
    // Initialize from Firebase snapshot data
    override
    init(snapshot:FIRDataSnapshot){
        self.childrenIDs = [:]
        // On intialization, parents may not have their children
        // assigned to them yet. In this case, set up an empty dictionary
        if ((snapshot.value!.objectForKey("childrenIDs")) != nil){
            self.childrenIDs = snapshot.value!["childrenIDs"] as! NSDictionary
        }
        super.init(
            key:snapshot.key,
            name:snapshot.value!["name"] as! String,
            email:snapshot.value!["email"] as! String,
            contactInfo:snapshot.value!["contactInfo"] as! String,
            isStaff:snapshot.value!["isStaff"] as! Bool)
    }
    
    // Initialize from Firebase authentication data
    override
    init(authData: FIRUser,name:String, contactInfo:String, isStaff:Bool){
        self.childrenIDs = [:]
        super.init(key:authData.uid.lowercaseString,
                   name:name,
                   email:authData.email!,
                   contactInfo:contactInfo,
                   isStaff:false)
    }
    
    // Convert to JSON object for pushing onto Firebase
    override
    func toAnyObject() -> AnyObject {
        return[
            "name": name,
            "email": email,
            "contactInfo": contactInfo,
            "isStaff": isStaff,
            "childrenIDs":childrenIDs
        ]
    }
}