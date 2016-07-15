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
        GMSServices.provideAPIKey("AIzaSyDRoeRl9n1-ZQMmAg3YnXJf_8iOmpIG54U")
        // [END initialize_firebase]
        return true
    }
    
}