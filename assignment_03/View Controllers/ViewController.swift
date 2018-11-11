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
    var destPlacemark : CLPlacemark? = nil
    var routeSteps = ["Enter a destination to see steps"] as NSMutableArray // List of directions.
    var srcPin : MKPointAnnotation? = nil // DropPin for starting location.
    var destPin : MKPointAnnotation? = nil // DropPin for destination location.
    var waypointPin1 : MKPointAnnotation = MKPointAnnotation() // DropPin for waypoint 1.
    var waypointPin2 : MKPointAnnotation = MKPointAnnotation() // DropPin for waypoint 2.
    
    
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
        let srcText = tfSourse.text
        let way1Text = tfWaypoint1.text
        let way2Text = tfWaypoint2.text
        let destText = tfDestination.text
        
        //TODO: Handle waypoints.
        // Convert locations into coordinates, and process route.
        self.forwardGeocode(address:srcText!, completion: { placemark in
            print("Src: \(String(describing: placemark))")
            self.srcPlacemark = placemark
            self.srcPin = self.drawDropPinOnMap(
                location: (self.srcPlacemark?.location)!,
                title: (placemark?.name)!,
                mapView: self.myMapView,
                oldPin: self.srcPin)
            self.requestDirections()
        })
        
        self.forwardGeocode(address:destText!, completion: { placemark in
            print("Dest: \(String(describing: placemark))")
            self.destPlacemark = placemark
            self.destPin = self.drawDropPinOnMap(
                location: (self.destPlacemark?.location)!,
                title: (placemark?.name)!,
                mapView: self.myMapView,
                oldPin: self.destPin)
            self.requestDirections()
        })
        
    }
    
    func forwardGeocode(address:String, completion:@escaping (CLPlacemark?) -> ()) {
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(address, completionHandler: {(placemarks, error) -> Void in
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
    
    func requestDirections() {
        // Converge async coordinate responses, and request directions b/w them.
        
        if (self.srcPlacemark != nil && self.destPlacemark != nil) {
            
            // Only if both placemarks have been found, request directions.
            let srcCoordinates : CLLocationCoordinate2D = (self.srcPlacemark?.location?.coordinate)!
            let destCoordinates : CLLocationCoordinate2D = (self.destPlacemark?.location?.coordinate)!
            
            let srcLocation = CLLocation(latitude: srcCoordinates.latitude,
                                         longitude: srcCoordinates.longitude)
            let destLocation = CLLocation(latitude: destCoordinates.latitude,
                                          longitude: destCoordinates.longitude)
            
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
            directionRequest.transportType = .automobile
            
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
                
                // Setting rect of our MapView to fit the two locations.
                let rect = route.polyline.boundingMapRect
                self.myMapView.setRegion(MKCoordinateRegionForMapRect(rect), animated: true)
            })
            
        }
        //TODO: Notify user of missing data.
    }
    
//
//    func calculateRouteRequest(request:MKDirectionsRequest) {
//        // Calculate travel route (async).
//        let directions = MKDirections(request: request)
//
//        // Handle route request response.
//        directions.calculate(completionHandler: {
//            [unowned self] response, error in
//            // Draw lines on map for User to follow while driving.
//            for route in (response?.routes)! {
//
//                // Add polyline to MapView.
//                self.myMapView.add(
//                    route.polyline,
//                    level : MKOverlayLevel.aboveRoads)
//
//                // Change visible portion of MapView.
//                self.myMapView.setVisibleMapRect(
//                    route.polyline.boundingMapRect,
//                    animated: true)
//
//                // Fill TableView with directions.
//                //TODO: Differentiate with SegmentView to add to.
//                self.routeSteps.removeAllObjects()
//                for step in route.steps {
//                    self.routeSteps.add(step.instructions)
//                }
//                // Update TableView with new directions.
//                self.myTableView.reloadData()
//            }
//        })
//    }
    
    
    
//    func findDestination(srcText:String, destText:String) {
//        // Handles finding routes to all locations.
//        let geoCoder = CLGeocoder()
//
//        geoCoder.geocodeAddressString(destText, completionHandler: {
//            (placemarks, error) -> Void in
//            // Error handling.
//            if error != nil {
//                print("Error in geocoder")
//                return
//            }
//
//            // Get location that matches the user's entered destination.
//            if let placemark = placemarks?.first {
//                // Coodinates (Latitude and longitude) of location.
//                let endCoordinates : CLLocationCoordinate2D = (placemark.location?.coordinate)!
//
//                // Convert coordinates to CLLocation object.
//                let endLocation = CLLocation(latitude: endCoordinates.latitude,
//                                             longitude: endCoordinates.longitude)
//
//                // Recenter map on destination.
//                //TODO: Center in between all locations.
//                self.centerMapOnLocation(location: endLocation)
//
//                // Create pin and drop.
//                //TODO: Remove existing pin.
//                self.destinationDropPin = self.drawDropPinOnMap(
//                    location: endLocation,
//                    title: placemark.name!,
//                    mapView: self.myMapView)
//
//                // Determine travel route.
//                let request = MKDirectionsRequest()
//                // Starting location.
//                request.source = MKMapItem(
//                    placemark: MKPlacemark(
//                        coordinate : self.initialLocation.coordinate
//                    )
//                )
//                // Destination location.
//                request.destination = MKMapItem(
//                    placemark : MKPlacemark(
//                        coordinate : endLocation.coordinate
//                    )
//                )
//                request.requestsAlternateRoutes = false
//                // Set transportation type to automobile.
//                request.transportType = .automobile
//
//                //
//                self.calculateRouteRequest(request:request)
//
//            }
//        })
//    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        // Customizes the appearance of polylines to be drawn on the MapView.
        
        // Obtain polyline renderer.
        let renderer = MKPolylineRenderer(polyline : overlay as! MKPolyline)
        
        // Configure the polyline appearance.
        renderer.strokeColor = .blue
        renderer.lineWidth = 3.0
        
        return renderer
    }
    
    func redrawDropPin(mapView:MKMapView, pin:MKPointAnnotation, location:CLLocation, title:String) {
        pin.coordinate = location.coordinate
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

