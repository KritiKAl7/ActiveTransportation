import Firebase
import Foundation
/**
 *  DbCommunicator
 *  DbCommunicator class saves the Refs that communicates with the database
 */
struct DbCommunicator {
    //var root = FIRDatabase.database()
    var rootRef: FIRDatabaseReference!
    let studentsRef: FIRDatabaseReference!
    let usersRef: FIRDatabaseReference!
    let routeRef: FIRDatabaseReference!
    let logRef: FIRDatabaseReference!
    var currentLogRef: FIRDatabaseReference!
    
    // Points to the current Firebase backend
    init(){
        self.rootRef = FIRDatabase.database().reference()
        self.studentsRef = rootRef.child("students")
        self.usersRef = rootRef.child("users")
        self.routeRef = rootRef.child("routes")
        self.logRef = rootRef.child("logs")
        self.currentLogRef = self.logRef
    }
    
    
}