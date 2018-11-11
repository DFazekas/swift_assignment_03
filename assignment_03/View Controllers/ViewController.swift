//
//  ViewController.swift
//  assignment_03
//
//  Created by Devon on 2018-11-08.
//  Copyright © 2018 PROG31975. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController, UITextViewDelegate, MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate {

    let locationManager = CLLocationManager() // Location manager.
    var srcPlacemark : CLPlacemark? = nil
    var way1Placemark : CLPlacemark? = nil
    var way2Placemark : CLPlacemark? = nil
    var destPlacemark : CLPlacemark? = nil
    var routeSteps = ["Enter a destination to see steps"] as NSMutableArray // List of directions.
    var srcPin : MKPointAnnotation? = nil // DropPin for starting location.
    var destPin : MKPointAnnotation? = nil // DropPin for destination location.
    var way1Pin : MKPointAnnotation? = nil // DropPin for waypoint 1.
    var way2Pin : MKPointAnnotation? = nil // DropPin for waypoint 2.
    var requestsWaiting : Int = 0 // Only process directions when zero.
    
    
    @IBOutlet var myMapView : MKMapView!
    @IBOutlet var tfSourse : UITextField!
    @IBOutlet var tfDestination : UITextField!
    @IBOutlet var tfWaypoint1 : UITextField!
    @IBOutlet var tfWaypoint2 : UITextField!
    @IBOutlet var myTableView : UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Center map on preset location.
        let initialLocation = CLLocation(latitude: 43.469147, longitude: -79.698603) // Initial location.
        centerMapOnLocation(location: initialLocation)
        
        // Set the pin on the map.
//        self.startingDropPin = self.drawDropPinOnMap(location: initialLocation, title: "Sheridan College", mapView: self.myMapView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MapView content.
    func centerMapOnLocation(location : CLLocation) {
        // Centers the MapView on the provided location.
        
        // Create new region.
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 2000, 2000)
        
        // Set MapView's region.
        myMapView.setRegion(coordinateRegion, animated: true)
    }

    @IBAction func submitLocations(sender : UIButton) {
        // Retrieve all destinations.
        let srcText = (tfSourse.text == "") ? nil : tfSourse.text
        let way1Text = (tfWaypoint1.text == "") ? nil : tfWaypoint1.text
        let way2Text = (tfWaypoint2.text == "") ? nil : tfWaypoint2.text
        let destText = (tfDestination.text == "") ? nil : tfDestination.text
        
        // Count number of locations to process.
        if srcText != nil { self.requestsWaiting += 1 }
        if way1Text != nil { self.requestsWaiting += 1 }
        if way2Text != nil { self.requestsWaiting += 1 }
        if destText != nil { self.requestsWaiting += 1 }
        
        // Clear all Pins from MapView.
        self.clearPins()
        
        // Convert locations into coordinates, and process route.
        self.forwardGeocode(address:srcText, completion: { placemark in
            if placemark != nil {
                self.requestsWaiting -= 1
                print("Src: \(String(describing: placemark))")
                self.srcPlacemark = placemark
                self.srcPin = self.drawDropPinOnMap(
                    location: (self.srcPlacemark?.location)!,
                    title: (placemark?.name)!,
                    mapView: self.myMapView,
                    oldPin: self.srcPin)
                self.requestDirections()
            }
        })
        
        self.forwardGeocode(address:way1Text, completion: { placemark in
            if placemark != nil {
                self.requestsWaiting -= 1
                print("Way1: \(String(describing: placemark))")
                self.way1Placemark = placemark
                self.way1Pin = self.drawDropPinOnMap(
                    location: (self.way1Placemark?.location)!,
                    title: (placemark?.name)!,
                    mapView: self.myMapView,
                    oldPin: self.way1Pin)
                self.requestDirections()
            }
        })
        
        self.forwardGeocode(address:way2Text, completion: { placemark in
            if placemark != nil {
                self.requestsWaiting -= 1
                print("Way2: \(String(describing: placemark))")
                self.way2Placemark = placemark
                self.way2Pin = self.drawDropPinOnMap(
                    location: (self.way2Placemark?.location)!,
                    title: (placemark?.name)!,
                    mapView: self.myMapView,
                    oldPin: self.way2Pin)
                self.requestDirections()
            }
        })
        
        self.forwardGeocode(address:destText, completion: { placemark in
            if placemark != nil {
                self.requestsWaiting -= 1
                print("Dest: \(String(describing: placemark))")
                self.destPlacemark = placemark
                self.destPin = self.drawDropPinOnMap(
                    location: (self.destPlacemark?.location)!,
                    title: (placemark?.name)!,
                    mapView: self.myMapView,
                    oldPin: self.destPin)
                self.requestDirections()
            }
        })
        
    }
    
    func forwardGeocode(address:String?, completion:@escaping (CLPlacemark?) -> ()) {
        if address == nil {
            completion(nil)
        }
        else {
            let geocoder = CLGeocoder()
            
            geocoder.geocodeAddressString(address!, completionHandler: {(placemarks, error) -> Void in
                if error != nil {
                    print("Error geoCoding text.")
                    completion(nil)
                }
                
                if let placemark = placemarks?.first {
                    //let coordinate : CLLocationCoordinate2D = placemark.location!.coordinate
                    completion(placemark)
                }
                
            })
        }
    }
    
    func requestDirections() {
        // Converge async coordinate responses, and request directions b/w them.
        print("RequestsWaiting: \(self.requestsWaiting)")
        // Only if both placemarks have been found, and no waypoints are pending, request directions.
        if ((self.requestsWaiting == 0) && (self.srcPlacemark != nil && self.destPlacemark != nil)) {
            
            // Convert placemarks into CLLocationCoordinate2D.
            let srcCoordinates : CLLocationCoordinate2D = (self.srcPlacemark?.location?.coordinate)!
            let destCoordinates : CLLocationCoordinate2D = (self.destPlacemark?.location?.coordinate)!
            
            // Create source & destination location objects.
            let srcLocation = CLLocation(latitude: srcCoordinates.latitude,
                                         longitude: srcCoordinates.longitude)
            let destLocation = CLLocation(latitude: destCoordinates.latitude,
                                          longitude: destCoordinates.longitude)
            
            // Build request for directions.
            let directionRequest = MKDirectionsRequest()
            directionRequest.source = MKMapItem(
                placemark : MKPlacemark(
                    coordinate : srcLocation.coordinate
                )
            )
            directionRequest.destination = MKMapItem(
                placemark : MKPlacemark(
                    coordinate : destLocation.coordinate
                )
            )
            
            // Set transport type to automobile.
            directionRequest.transportType = .automobile
            
            // Send async request for directions.
            let directions = MKDirections(request: directionRequest)
            directions.calculate(completionHandler: { (response, error) in
                guard let directionResponse = response else {
                    
                    // Error handling.
                    if let error = error {
                        print("Error getting directions \n\(error.localizedDescription)")
                    }
                    return
                }
                
                // Get route and assign to our route variable.
                let route = directionResponse.routes[0]
                
                // Add route to our MapView.
                self.myMapView.add(
                    route.polyline,
                    level: .aboveRoads)
                
                // Set rect of our MapView to fit the two locations.
                let rect = route.polyline.boundingMapRect
                self.myMapView.setRegion(MKCoordinateRegionForMapRect(rect), animated: true)
                
                self.routeSteps.removeAllObjects()
                for step in route.steps {
                    self.routeSteps.add(step.instructions)
                }
                // Update TableView with new directions.
                self.myTableView.reloadData()
            })
            
        }
        //TODO: Notify user of missing data.
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        // Customizes the appearance of polylines to be drawn on the MapView.
        
        // Obtain polyline renderer.
        let renderer = MKPolylineRenderer(polyline : overlay as! MKPolyline)
        
        // Configure the polyline appearance.
        renderer.strokeColor = .blue
        renderer.lineWidth = 3.0
        
        return renderer
    }

    func drawDropPinOnMap(location:CLLocation, title:String, mapView:MKMapView, oldPin:MKPointAnnotation?) -> MKPointAnnotation {
        // Draw named DropPin on MapView, returning DropPin.
        
        if oldPin != nil {
            // Relocate Pin.
            oldPin?.coordinate = location.coordinate
            return oldPin!
        }
        else {
            // Create new Pin.
            let pin = MKPointAnnotation()
            pin.coordinate = location.coordinate
            pin.title = title
            mapView.addAnnotation(pin)
            mapView.selectAnnotation(pin, animated: true)
            return pin
        }
    }
    
    func clearPins() {
        // Clear any existing Pins on the MapView.
        
        if self.srcPin != nil {
            self.myMapView.removeAnnotation(self.srcPin!)
            self.srcPin = nil
        }
        if self.way1Pin != nil {
            self.myMapView.removeAnnotation(self.way1Pin!)
            self.way1Pin = nil
        }
        if self.way2Pin != nil {
            self.myMapView.removeAnnotation(self.way2Pin!)
            self.way2Pin = nil
        }
        if self.destPin != nil {
            self.myMapView.removeAnnotation(self.destPin!)
            self.destPin = nil
        }
    }
    
    // TableView content.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return routeSteps.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 30
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableCell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell()
        tableCell.textLabel?.text = routeSteps[indexPath.row] as? String
        
        return tableCell
    }


    // Keyboard content.
    func textFieldShouldReturn(textField : UITextField) -> Bool {
        return textField.resignFirstResponder()
    }

}

