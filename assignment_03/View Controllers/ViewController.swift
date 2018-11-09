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
    let initialLocation = CLLocation(latitude: 43.469147, longitude: -79.698603) // Initial location.
    var routeSteps = ["Enter a destination to see steps"] as NSMutableArray // List of directions.
    
    @IBOutlet var myMapView : MKMapView!
    @IBOutlet var tfDestination : UITextField!
    @IBOutlet var tfWaypoint1 : UITextField!
    @IBOutlet var tfWaypoint2 : UITextField!
    @IBOutlet var myTableView : UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Center map on preset location.
        centerMapOnLocation(location: initialLocation)
        
        // Set the pin on the map.
        self.drawDropPinOnMap(location: initialLocation, title: "Sheridan College")
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

    @IBAction func findDestination(sender : UIButton) {
        let destinationText = tfDestination.text
        let geoCoder = CLGeocoder()
        
        geoCoder.geocodeAddressString(destinationText!, completionHandler: {
            (placemarks, error) -> Void in
                // Error handling.
            if error != nil {
                print("Error in geocoder")
            }
            
            // Get location that matches the user's entered destination.
            if let placemark = placemarks?.first {
                // Coodinates (Latitude and longitude) of location.
                let coordinates : CLLocationCoordinate2D = (placemark.location?.coordinate)!
                
                // Convert coordinates to CLLocation object.
                let newLocation = CLLocation(latitude: coordinates.latitude,
                                             longitude: coordinates.longitude)
                
                // Recenter map on destination.
                //TODO: Center in between all locations.
                self.centerMapOnLocation(location: newLocation)
                
                // Create pin and drop.
                //TODO: Remove existing pin.
                self.drawDropPinOnMap(location: newLocation, title: placemark.name!)
                
                
                // Determine travel route.
                let request = MKDirectionsRequest()
                // Starting location.
                request.source = MKMapItem(
                    placemark: MKPlacemark(
                        coordinate : self.initialLocation.coordinate
                    )
                )
                // Destination location.
                request.destination = MKMapItem(
                    placemark : MKPlacemark(
                        coordinate : newLocation.coordinate
                    )
                )
                request.requestsAlternateRoutes = false
                // Set transportation type to automobile.
                request.transportType = .automobile
                
                // Calculate travel route.
                let directions = MKDirections(request: request)
                directions.calculate(completionHandler: {
                    [unowned self] response, error in
                    // Draw lines on map for User to follow while driving.
                    for route in (response?.routes)! {
                        self.myMapView.add(route.polyline, level : MKOverlayLevel.aboveRoads)
                        self.myMapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                        
                        // Fill TableView with directions.
                        self.routeSteps.removeAllObjects()
                        for step in route.steps {
                            self.routeSteps.add(step.instructions)
                        }
                        // Update TableView with new directions.
                        self.myTableView.reloadData()
                    }
                })
            }
        })
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
    
    func drawDropPinOnMap(location : CLLocation, title : String) {
        // Draw named DropPin on MapView.
        
        let dropPin = MKPointAnnotation()
        dropPin.coordinate = location.coordinate
        dropPin.title = title
        self.myMapView.addAnnotation(dropPin)
        self.myMapView.selectAnnotation(dropPin, animated: true)
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

