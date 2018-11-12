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
    var circle : MKCircle? = nil // Circle overlay around source coordinates.
    var srcPlacemark : CLPlacemark? = nil
    var way1Placemark : CLPlacemark? = nil
    var way2Placemark : CLPlacemark? = nil
    var destPlacemark : CLPlacemark? = nil
    var allRoutes = [Int: MKRoute]() // Directory of routes with keys representing order of execution.
    var routeSteps = ["Enter a destination to see steps"] as NSMutableArray // List of directions to display.
    var requestsWaiting : Int = 0 // Used to converge async calls.
    let radius = 25000 // Radius around Source.
    
    @IBOutlet var myMapView : MKMapView!
    @IBOutlet var tfSourse : UITextField!
    @IBOutlet var tfDestination : UITextField!
    @IBOutlet var tfWaypoint1 : UITextField!
    @IBOutlet var tfWaypoint2 : UITextField!
    @IBOutlet var myTableView : UITableView!
    @IBOutlet var mySegmentView : UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Center map on preset location.
        let initialLocation = CLLocation(latitude: 43.469147, longitude: -79.698603) // Initial location.
        centerMapOnLocation(location: initialLocation)
        
        // Clear SegmentView.
        mySegmentView.removeAllSegments()
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
        
        // Clear any persisting data.
        self.clearMap()
        self.clearDirections()
        self.allRoutes.removeAll()
        self.mySegmentView.removeAllSegments()
        
        // Convert locations into coordinates, and process route.
        self.forwardGeocode(address:srcText, completion: { placemark in
            if placemark != nil {
                
                // Async request responsed, reduce counter.
                self.requestsWaiting -= 1
                
                self.srcPlacemark = placemark
                
                // Place Pin.
                self.drawDropPinOnMap(
                    location: (self.srcPlacemark?.location)!,
                    title: (placemark?.name)!,
                    mapView: self.myMapView
                )
                
                // Attempt converging async responses.
                self.convergeCoordRequests()
            } else {
                self.srcPlacemark = nil
            }
        })
        
        self.forwardGeocode(address:way1Text, completion: { placemark in
            if placemark != nil {
                
                // Async request responsed, reduce counter.
                self.requestsWaiting -= 1
                
                self.way1Placemark = placemark
                
                // Place Pin.
                self.drawDropPinOnMap(
                    location: (self.way1Placemark?.location)!,
                    title: (placemark?.name)!,
                    mapView: self.myMapView
                )
                
                // Attempt converging async responses.
                self.convergeCoordRequests()
            } else {
                self.way1Placemark = nil
            }
        })
        
        self.forwardGeocode(address:way2Text, completion: { placemark in
            if placemark != nil {
                // Async request responsed, reduce counter.
                self.requestsWaiting -= 1
                
                self.way2Placemark = placemark
                
                // Place Pin.
                self.drawDropPinOnMap(
                    location: (self.way2Placemark?.location)!,
                    title: (placemark?.name)!,
                    mapView: self.myMapView
                )
                
                // Attempt converging async responses.
                self.convergeCoordRequests()
            } else {
                self.way2Placemark = nil
            }
        })
        
        self.forwardGeocode(address:destText, completion: { placemark in
            if placemark != nil {
                
                // Async request responsed, reduce counter.
                self.requestsWaiting -= 1
                
                self.destPlacemark = placemark
                
                // Place Pin.
                self.drawDropPinOnMap(
                    location: (self.destPlacemark?.location)!,
                    title: (placemark?.name)!,
                    mapView: self.myMapView
                )
                
                // Attempt converging async responses.
                self.convergeCoordRequests()
            } else {
                self.destPlacemark = nil
            }
        })
        
    }
    
    func forwardGeocode(address:String?, completion:@escaping (CLPlacemark?) -> ()) {
        // Async decodes string address into coordinates.
        
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
    
    func convergeCoordRequests() {
        // Converge async coordinate responses, and request directions b/w them.
        
        // Only if both placemarks have been found, and no waypoints are pending, request directions.
        if ((self.requestsWaiting == 0) && (self.srcPlacemark != nil && self.destPlacemark != nil)) {
        
            // Processes the route b/w 2 coordinates (src & dest).
            var placemarks : [CLPlacemark] = []
            var outOfBoundsNames : [String] = []
            
            if self.srcPlacemark != nil {
                placemarks.append(self.srcPlacemark!)
                
                // Redraw circle on MapView around source coordinates.
                self.circle = addBoundary(center: (self.srcPlacemark?.location?.coordinate)!, oldCircle:self.circle)
            }
            if self.way1Placemark != nil {
                placemarks.append(self.way1Placemark!)
                
                if checkAgainstRadius(placemark:self.way1Placemark!) == false {
                    outOfBoundsNames.append((self.way1Placemark?.name!)!)
                }
            }
            if self.way2Placemark != nil {
                placemarks.append(self.way2Placemark!)
                
                if checkAgainstRadius(placemark:self.way2Placemark!) == false {
                    outOfBoundsNames.append((self.way2Placemark?.name!)!)
                }
            }
            if self.destPlacemark != nil {
                placemarks.append(self.destPlacemark!)
                
                if checkAgainstRadius(placemark:self.destPlacemark!) == false {
                    outOfBoundsNames.append((self.destPlacemark?.name!)!)
                }
            }
            
            // Inform user of any locations outside the source radius.
            self.alertUser(titles: outOfBoundsNames, srcTitle: (self.srcPlacemark?.name)!)
            
            // Iterate through placemarks, processing the routes of two coordinates at a time.
            for index in 0 ..< placemarks.count - 1 {
                self.requestsWaiting += 1
                findRoute(srcPlacemark:placemarks[index], destPlacemark:placemarks[index+1], index:index)
            }
            
            // Print all directions at once.
            self.printDirections()
            
        }
    }
    
    func checkAgainstRadius(placemark:CLPlacemark) -> Bool {
        // Return TRUE if outside source's radius; FALSE otherwise.
        
        // Distance b/w placemark and source, in meters (1 mile = 1609 meters).
        let distanceFromSource = placemark.location?.distance(from: (self.srcPlacemark?.location)!)
        
        return (distanceFromSource?.magnitude)! < Double(self.radius)
    }
    
    func findRoute(srcPlacemark:CLPlacemark, destPlacemark:CLPlacemark, index:Int) {
        // Convert placemarks into CLLocationCoordinate2D.
        let srcCoordinates : CLLocationCoordinate2D = (srcPlacemark.location?.coordinate)!
        let destCoordinates : CLLocationCoordinate2D = (destPlacemark.location?.coordinate)!
        
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
            
            // Async response, reduce counter.
            self.requestsWaiting -= 1
            
            guard let directionResponse = response else {
                // Error handling.
                if let error = error {
                    print("Error getting directions \n\(error.localizedDescription)")
                }
                return
            }
            
            
            // Get route and assign to our route variable.
            let route = directionResponse.routes[0]
            self.allRoutes[index] = route
            
            // Add route to our MapView.
            self.myMapView.add(
                route.polyline,
                level: .aboveRoads)
            
            // Set rect of our MapView to fit the two locations.
            let rect = route.polyline.boundingMapRect
            self.myMapView.setRegion(MKCoordinateRegionForMapRect(rect), animated: true)
    
            self.printDirections()
        })
    }
    
    func printDirections() {
        // Get directions.
        if self.requestsWaiting == 0 {
            // Display directions in TableView.
            for (index, route) in self.allRoutes.enumerated() {
                
                // Creates title for SegmentControl.
                let title = (index != self.allRoutes.count - 1) ? "Stop \(index+1)" : "Destination"
                
                // Creates new SegmentControl
                self.mySegmentView.insertSegment(withTitle: title, at: index, animated: true)
                
                // Stores all directions for one route.
                for step in route.value.steps {
                    self.routeSteps.add(step.instructions)
                }
            }
            
            // Update TableView with new directions.
            self.myTableView.reloadData()
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        // Customizes the appearance of polylines and circles to be drawn on the MapView.
        if overlay is MKPolyline {
            // Obtain polyline renderer.
            let renderer = MKPolylineRenderer(polyline : overlay as! MKPolyline)
            
            // Configure the polyline appearance.
            renderer.strokeColor = .blue
            renderer.lineWidth = 3.0
            return renderer
        }
        else if overlay is MKCircle {
            // Obtain circle renderer.
            let renderer = MKCircleRenderer(circle: overlay as! MKCircle)
            
            // Configure the circle appearance.
            renderer.strokeColor = UIColor.red
            renderer.fillColor = UIColor(red: 255, green: 0, blue: 0, alpha: 0.1)
            renderer.lineWidth = 2.0
            return renderer
        }
        
        return MKOverlayRenderer()
    }

    func drawDropPinOnMap(location:CLLocation, title:String, mapView:MKMapView) {
        // Draw named DropPin on MapView, returning DropPin.
    
        let pin = MKPointAnnotation()
        pin.coordinate = location.coordinate
        pin.title = title
        mapView.addAnnotation(pin)
        mapView.selectAnnotation(pin, animated: true)
    }
    
    func clearMap() {
        // Clear any existing Pins on the MapView.
        
        let allAnnotations = self.myMapView.annotations
        self.myMapView.removeAnnotations(allAnnotations)
        
        let allOverlays = self.myMapView.overlays
        self.myMapView.removeOverlays(allOverlays)
    }

    func addBoundary(center:CLLocationCoordinate2D, oldCircle:MKCircle?) -> MKCircle {
        // Draws a circle around the source coordinates.
        
        if oldCircle != nil {
            self.myMapView.remove(oldCircle!)
        }
        
        let circle = MKCircle(center: center, radius: CLLocationDistance(self.radius))
        self.myMapView.add(circle)
        return circle
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

    func clearDirections() {
        // Clear directions.
        
        self.routeSteps.removeAllObjects()
    }
    
    
    // SegmentedView content.
    @IBAction func segmentChanged(sender : UISegmentedControl) {
        // Handles SegmentControl value change - display directions.
        
        self.routeSteps.removeAllObjects()
        
        let index = sender.selectedSegmentIndex
        let route = self.allRoutes[index]
        for step in (route?.steps)! {
            self.routeSteps.add(step.instructions)
        }
        
        // Update TableView with new directions.
        self.myTableView.reloadData()
    }
    
    
    // Alert content.
    func alertUser(titles:[String], srcTitle:String) {
        // Alert the user of the locations that are outside the source coordinate.
        if !titles.isEmpty {
            let alert = UIAlertController(
                title: "Out of bounds",
                message: "The following locations are outside the 25km radius around \(srcTitle):\n\(titles)",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
            
            self.present(alert, animated: true)
        }
    }
    
    
    // Keyboard content.
    func textFieldShouldReturn(textField : UITextField) -> Bool {
        return textField.resignFirstResponder()
    }

}

