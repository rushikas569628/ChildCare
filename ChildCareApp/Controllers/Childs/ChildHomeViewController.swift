//
//  ChildHomeViewController.swift
//  ChildCareApp
//
//  Created by Benitha on 18/02/2025.
//

import UIKit
import GoogleMaps
import CoreLocation
import FirebaseAuth
import FirebaseFirestore

class ChildHomeViewController: UIViewController {
    
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var addressLBL: UILabel!
    
    var locationManager = CLLocationManager()
    var selectedLocation: CLLocation?
    var parentID = ""
    var childDocID = ""
    var locationTimer: Timer?
    
    var restrictedLocations: [RestrictedLocationModel] = []
    var isMapDragged = false
    
    var isAlertAlreadyShown = false
    
    // Device Mapping Dictionary
    let modelMapping: [String: String] = [
        "iPhone10,3": "iPhone X",
        "iPhone10,6": "iPhone X",
        "iPhone11,8": "iPhone XR",
        "iPhone11,2": "iPhone XS",
        "iPhone11,6": "iPhone XS Max",
        "iPhone12,1": "iPhone 11",
        "iPhone12,3": "iPhone 11 Pro",
        "iPhone12,5": "iPhone 11 Pro Max",
        "iPhone13,1": "iPhone 12 mini",
        "iPhone13,2": "iPhone 12",
        "iPhone13,3": "iPhone 12 Pro",
        "iPhone13,4": "iPhone 12 Pro Max",
        "iPhone14,4": "iPhone 13 mini",
        "iPhone14,5": "iPhone 13",
        "iPhone14,2": "iPhone 13 Pro",
        "iPhone14,3": "iPhone 13 Pro Max",
        "iPhone14,7": "iPhone 14",
        "iPhone14,8": "iPhone 14 Plus",
        "iPhone15,2": "iPhone 14 Pro",
        "iPhone15,3": "iPhone 14 Pro Max",
        "iPhone15,4": "iPhone 15",
        "iPhone15,5": "iPhone 15 Plus",
        "iPhone16,1": "iPhone 15 Pro",
        "iPhone16,2": "iPhone 15 Pro Max",
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initializeMap()
        self.initializeLocationManager()
        
        self.getChildData()
        locationTimer = Timer.scheduledTimer(timeInterval: 20, target: self, selector: #selector(updateChildLocation), userInfo: nil, repeats: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            
            self.updateChildLocation()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            
            self.getChildRestrictedLocations()
        }
        
        // Do any additional setup after loading the view.
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        locationManager.stopUpdatingLocation()
    }
    
    
    func initializeMap() -> Void {
        
        mapView.delegate = self
        mapView.isMyLocationEnabled = true
        mapView.settings.tiltGestures = false
        mapView.settings.rotateGestures = true
        mapView.settings.allowScrollGesturesDuringRotateOrZoom = false
    }
    
    func initializeLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.requestWhenInUseAuthorization()
        locationManager.distanceFilter = 100  // Update only after moving 100 meters
        locationManager.headingFilter = CLLocationDegrees(1)
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.startUpdatingLocation()
    }

    
    func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let identifier = withUnsafeBytes(of: &systemInfo.machine) { buffer in
            buffer.compactMap { $0 != 0 ? String(UnicodeScalar(UInt8($0))) : nil }.joined()
        }
        
        return modelMapping[identifier] ?? identifier // Return model name if found, else return identifier
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    func getChildData() {
        let database = Firestore.firestore()
        let id = Auth.auth().currentUser?.uid ?? ""
        
        let docRef = database.collection("Childs")
            .whereField("id", isEqualTo: id)
        
        docRef.addSnapshotListener { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                if let document = querySnapshot?.documents.first {
                    self.childDocID = document.documentID
                    let data = document.data()
                    self.parentID = data["parent_id"] as? String ?? ""
                    
                    // Guard against empty IDs
                    if self.childDocID.isEmpty || self.parentID.isEmpty {
                        print("Error: Document ID or Parent ID is empty!")
                        return
                    }
                    
                    self.saveDeviceForUser()
                }
            }
        }
    }

    
    
    func saveDeviceForUser() {
        
        let db = Firestore.firestore()
        let id = Auth.auth().currentUser?.uid ?? ""
        // Get the unique device ID
        
        // Reference to Firestore collection
        let deviceRef = db.collection("Devices")
            .whereField("child_id", isEqualTo: id)
            .whereField("model", isEqualTo: UIDevice.current.model)
        
        deviceRef.addSnapshotListener { (querySnapshot, err) in
            if let err = err {
                
                print("Error getting documents: \(err)")
                
            } else {
                
                if querySnapshot?.documents.count ?? 0 == 0 {
                    
                    self.addDevice()
                }
            }
        }
    }
    
    var lastNotifiedLocationID: String?
    var lastNotificationTime: Date?
    let notificationCooldownInterval: TimeInterval = 300  // 5 minutes
    
 


    
    func checkForRestrictedArea() {
        guard let currentLocation = selectedLocation else { return }

        // Loop through all restricted locations
        for restrictedLocation in restrictedLocations {
            let restrictedLoc = CLLocation(latitude: restrictedLocation.lat ?? 0.0, longitude: restrictedLocation.lng ?? 0.0)
            let distance = currentLocation.distance(from: restrictedLoc) // Distance in meters

            // Debugging statement
            print("Distance from restricted location (\(restrictedLocation.title ?? "")): \(distance) meters")

            // Check if the distance is less than or equal to 100 meters
            if distance <= 100 {
                if !isAlertAlreadyShown {
                    isAlertAlreadyShown = true
                    showAlert()  // Show alert to the user (child)
                    sendNotificationToParent()  // Send notification to the parent
                }
                
                // Update last notification tracking
                lastNotifiedLocationID = restrictedLocation.id
                lastNotificationTime = Date()

                break  // Exit the loop once a restricted area is found
            } else {
                // Reset the alert if the child is not in the restricted area
                isAlertAlreadyShown = false
            }
        }
    }



    

    // This method sends a notification to the parent when the child enters a restricted area
    func sendNotificationToParent() {
        guard !parentID.isEmpty, !childDocID.isEmpty else {
            print("Error: Parent ID or Child Doc ID is empty.")
            return
        }

        let path = "Notifications"
        let db = Firestore.firestore()

        let id = Auth.auth().currentUser?.uid ?? ""  // Child's ID
        let name = Auth.auth().currentUser?.displayName ?? ""
        let myTimeStamp = Date().timeIntervalSince1970

        let notifData: [String: Any] = [
            "child_name": name,
            "parent_id": parentID,
            "child_id": id,
            "type": 3,  // Restricted area alert
            "lat": selectedLocation?.coordinate.latitude ?? 0.0,
            "lng": selectedLocation?.coordinate.longitude ?? 0.0,
            "address": self.addressLBL.text ?? "",
            "timestamp": myTimeStamp
        ]

        db.collection(path).document().setData(notifData) { err in
            if let error = err {
                print("Error sending notification to parent: \(error.localizedDescription)")
            } else {
                print("Notification successfully sent to the parent")
            }
        }
    }



    
    // Show an alert to the child when entering a restricted area
    func showAlert() {
        let alert = UIAlertController(title: "Warning", message: "You are within 100 meters of a restricted area!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    @objc func updateChildLocation() {
        guard let currentLocation = selectedLocation, !childDocID.isEmpty else {
            print("Error: Child Doc ID is empty or location is not set")
            return
        }

        let path = "Childs"
        let db = Firestore.firestore()
        
        let params: [String: Any] = [
            "lat": currentLocation.coordinate.latitude,
            "lng": currentLocation.coordinate.longitude,
            "address": addressLBL.text ?? ""
        ]

        db.collection(path).document(childDocID).updateData(params) { error in
            if let error = error {
                print("Error updating location: \(error.localizedDescription)")
            } else {
                print("Child location successfully updated")
            }
        }
    }

    func addDevice() {
        
        let path = String(format: "%@", "Devices")
        let db = Firestore.firestore()
        
        guard let deviceID = UIDevice.current.identifierForVendor?.uuidString else { return }
        let id = Auth.auth().currentUser?.uid ?? ""
        let name = Auth.auth().currentUser?.displayName ?? ""
        
        let deviceData: [String: Any] = [
            "child_name": name,
            "parent_id": self.parentID,
            "child_id": id,
            "deviceID": deviceID,
            "model": UIDevice.current.model,
            "systemVersion": UIDevice.current.systemVersion,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        db.collection(path).document().setData(deviceData) { err in
            if let _ = err {
                
            } else {
                
            }
        }
    }
    
    @IBAction func current(_ sender: Any) {
        
        self.isMapDragged = false
        self.initializeLocationManager()
    }
    
    func getChildRestrictedLocations() {
        let database = Firestore.firestore()
        let id = Auth.auth().currentUser?.uid ?? ""

        let docRef = database.collection("Restricted_Locations")
            .whereField("child_id", isEqualTo: id)

        docRef.addSnapshotListener { (querySnapshot, err) in
            if let err = err {
                print("Error getting restricted locations: \(err)")
            } else {
                self.restrictedLocations.removeAll()
                for document in querySnapshot!.documents {
                    print("\(document.documentID) => \(document.data())")

                    let data = document.data()
                    var model = RestrictedLocationModel()

                    model.id = document.documentID
                    model.parent_id = data["parent_id"] as? String ?? ""
                    model.child_id = data["child_id"] as? String ?? ""
                    model.title = data["title"] as? String ?? ""
                    model.address = data["address"] as? String ?? ""
                    model.lat = data["lat"] as? Double ?? 0.0
                    model.lng = data["lng"] as? Double ?? 0.0

                    self.restrictedLocations.append(model)
                }
                print("Loaded Restricted Locations: \(self.restrictedLocations)") // Debugging line
            }
        }
    }


}


extension ChildHomeViewController: CLLocationManagerDelegate {
    
    private func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        print("====\(status) ====")
        switch status {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
            break
        case .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
            break
        case .authorizedAlways:
            locationManager.startUpdatingLocation()
            break
        case .restricted:
            break
        case .denied:
            break
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else { return }

        selectedLocation = currentLocation

        let camera = GMSCameraPosition.camera(
            withLatitude: currentLocation.coordinate.latitude,
            longitude: currentLocation.coordinate.longitude,
            zoom: 15.0
        )

        mapView.animate(to: camera)

        // Update child's location in Firestore
        updateChildLocation()
    }




    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location update failed with error: \(error.localizedDescription)")
    }
    
    func sendNotification() -> Void {
        
        let path = String(format: "%@", "Notifications")
        let db = Firestore.firestore()
        
        let id = Auth.auth().currentUser?.uid ?? ""
        let name = Auth.auth().currentUser?.displayName ?? ""
        
        let myTimeStamp = Date().timeIntervalSince1970
        
        let notifData: [String: Any] = [
            "child_name": name,
            "parent_id": self.parentID,
            "child_id": id,
            "type": 3,
            "lat": selectedLocation?.coordinate.latitude ?? 0.0,
            "lng": selectedLocation?.coordinate.longitude ?? 0.0,
            "address": self.addressLBL.text ?? "",
            "timestamp": myTimeStamp
        ]
        
        db.collection(path).document().setData(notifData) { err in
            if let _ = err {
                
            } else {
                
            }
        }
    }
}

extension ChildHomeViewController: GMSMapViewDelegate {
    
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        if gesture {
            isMapDragged = true
            print("User is dragging the map")
        } else {
            print("Map movement is automatic")
        }
    }


    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        let geocoder = GMSGeocoder()
        let location = CLLocation(latitude: position.target.latitude, longitude: position.target.longitude)

        // Ensure that dragging state is handled properly
        if isMapDragged {
            isMapDragged = false  // Reset dragging state
        }

        geocoder.reverseGeocodeCoordinate(location.coordinate) { response, error in
            guard error == nil, let result = response?.firstResult() else {
                print("Geocoding error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            self.selectedLocation = location  // Update the selected location

            // Construct address string
            var addressParts: [String] = []
            if let thoroughfare = result.thoroughfare { addressParts.append(thoroughfare) }
            if let sublocality = result.subLocality { addressParts.append(sublocality) }
            if let locality = result.locality { addressParts.append(locality) }
            if let country = result.country { addressParts.append(country) }

            let fullAddress = addressParts.joined(separator: ", ")
            self.addressLBL.text = fullAddress
            print("Updated Address: \(fullAddress)")

            // 🔥 Update Firestore after user moves the map
            self.updateChildLocation()
        }
    }


}
