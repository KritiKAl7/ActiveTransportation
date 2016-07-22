//
//  MapsViewController.swift
//  ActiveTransportation
//
//  Created by cssummer16 on 7/13/16.
//
//

import Foundation
import UIKit
import GoogleMaps
import Toast_Swift
import CoreLocation

class MapsViewController: UITableViewController {
    var students = [Student]()
    var dbComm = DbCommunicator()
    var latitudes = [Double]()
    var longitudes = [Double]()
    var legitStudents = [String]()
    var index = 0
    var mapView = GMSMapView.mapWithFrame(CGRectZero, camera: GMSCameraPosition.cameraWithLatitude(0, longitude: 0, zoom: 1))
    
    override func loadView() {
        super.loadView()
        //Pre-set the camera according to the user's time zone
        let hoursFromGMT: Int = NSTimeZone.localTimeZone().secondsFromGMT / 3600
        let camera = GMSCameraPosition.cameraWithLatitude(40.0, longitude: Double (hoursFromGMT * 15), zoom:4)
        mapView = GMSMapView.mapWithFrame(CGRectZero, camera: camera)
        self.view = mapView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if (!self.students.isEmpty) {
            //If there is available location data, start updating the markers on the map
            var updateTime = NSTimer.scheduledTimerWithTimeInterval(10.0, target: self, selector: Selector("updateLocations"), userInfo: nil, repeats: true)
        } else {
            self.view.makeToast("No Location Data Available", duration: 1.5, position: CGPoint(x:200.0, y:500.0))
        }
    }
    
    
    @IBAction func nextDidTouch(sender: AnyObject) {
        //Rotate the camera among the markers representing each kids
        if(legitStudents.count > index){
            let currCamera = GMSCameraPosition.cameraWithLatitude(latitudes[index], longitude: longitudes[index], zoom: 12)
            mapView.camera = currCamera
            index += 1
            if (index >= legitStudents.count) {
                index = 0
            }
        } else {
            self.view.makeToast("No Location Data Available", duration: 1.5, position: CGPoint(x:200.0, y:500.0))
        }
    }
    
    func updateLocations() {
        //main function that updates the markers on tha map
        if (!self.students.isEmpty) {
            self.mapView.clear()
            for student in self.students {
                dbComm.routeRef.child(student.routeID).observeEventType(.Value, withBlock: {snapshot in
                    if (snapshot.hasChild("currLocation")) {
                        let current:Bool = snapshot.value!["currLocation"]!!["current"] as! Bool
                        if (current) {
                            self.latitudes.append((snapshot.value!["currLocation"]!!["Latitude"] as! Double))
                            self.longitudes.append((snapshot.value!["currLocation"]!!["Longitude"] as! Double))
                            self.legitStudents.append(student.name)
                            let position = CLLocationCoordinate2D(latitude:self.latitudes.last!, longitude:self.longitudes.last!)
                            let marker = GMSMarker(position: position)
                            marker.title = student.name
                            marker.map = self.mapView
                        }
                    }
                })
            }
        }
    }
    
    
}
