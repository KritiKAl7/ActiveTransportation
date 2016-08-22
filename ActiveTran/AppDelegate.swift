import UIKit
import Firebase
import GoogleMaps

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    override init() {
        FIRApp.configure()
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // [START initialize_firebase]
        GMSServices.provideAPIKey("AIzaSyDGwL7607QkOE71-j3Q6V8wm7Wj1R_4tLc")
        // [END initialize_firebase]
        return true
    }
    
}