//
//  FCViewController.swift
//  TestMapApp
//
//  Created by Tsenguun Batbold on 25/9/20.
//

import UIKit
import MapKit
import Contacts
import os.log
import CoreBluetooth
import Alamofire
import CoreLocation

struct MyPeripheral{
    var CBP:CBPeripheral
    var discovered_time: TimeInterval
    var rssi:NSNumber
    
    init(CBP: CBPeripheral, discovered_time:TimeInterval, rssi:NSNumber) {
        self.CBP = CBP
        self.discovered_time = discovered_time
        self.rssi = rssi
    }
}

struct SensorData: Encodable {
    var region:String
    var begin_longitude:Double
    var begin_latitude:Double
    var end_longitude:Double
    var end_latitude:Double
    var device:String
    var sensor_data: [[IBeacon]]
}

struct PredictionData: Encodable {
    var region:String
    var device:String
    var sensor_data: [IBeacon]
}

func convertToDictionary(text: String) -> [String: Any]? {
    if let data = text.data(using: .utf8) {
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print(error.localizedDescription)
        }
    }
    return nil
}

struct FloorPlan {
    let center: CLLocationCoordinate2D
    let topLeft: CLLocationCoordinate2D
    let corners: [CLLocationCoordinate2D]
    let bearing: Double
    let widthMeters: Float
    let heightMeters: Float
    let url: String
}

struct IBeacon: Encodable {
    let uuid: String
    let major: Int
    let minor: Int
    let rssi: Int
}

// Function to convert degrees to radians
func degreesToRadians(_ x:Double) -> Double {
    return (Double.pi * x / 180.0)
}

// Class for map overlay object
class MapOverlay: NSObject, MKOverlay {
    var coordinate: CLLocationCoordinate2D
    var boundingMapRect: MKMapRect
    
    
    // Initializer for the class
    init(floorPlan: Floor, andRotatedRect rotated: CGRect) {
        
        let center = CLLocationCoordinate2D(latitude: floorPlan.center?.lat ?? 0, longitude: floorPlan.center?.lng ?? 0)
        
        coordinate = center
        
        
        // Area coordinates for the overlay
        let topLeft = MKMapPoint(CLLocationCoordinate2D(latitude: floorPlan.corners?[0].lat ?? 0, longitude: floorPlan.corners?[0].lng ?? 0))
        let bottomRight = MKMapPoint(CLLocationCoordinate2D(latitude: floorPlan.corners?[3].lat ?? 0, longitude: floorPlan.corners?[3].lng ?? 0))
        boundingMapRect = MKMapRect(x: topLeft.x + Double(rotated.origin.x), y: topLeft.y + Double(rotated.origin.y), width: fabs(bottomRight.x - topLeft.x), height: fabs(bottomRight.y - topLeft.y))
    }
}

// Class for rendering map overlay objects
class MapOverlayRenderer: MKOverlayRenderer {
    var overlayImage: UIImage
    var floorPlan: Floor
    var rotated: CGRect
    
    init(overlay:MKOverlay, overlayImage:UIImage, fp: Floor, rotated: CGRect) {
        self.overlayImage = overlayImage
        self.floorPlan = fp
        self.rotated = rotated
        super.init(overlay: overlay)
    }
    
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in ctx: CGContext) {
    
        
        // Width and height in MapPoints for the floorplan
        let mapPointsPerMeter = MKMapPointsPerMeterAtLatitude(floorPlan.center?.lat ?? 0)
        let rect = CGRect(x: 0, y: 0, width: Double(floorPlan.width ?? 0) * mapPointsPerMeter, height: Double(floorPlan.height ?? 0) * mapPointsPerMeter)
        ctx.translateBy(x: -rotated.origin.x, y: -rotated.origin.y)

        // Rotate around top left corner
        ctx.rotate(by: CGFloat(degreesToRadians(floorPlan.bearing ?? 0)));

        // Draw the floorplan image
        UIGraphicsPushContext(ctx)
        overlayImage.draw(in: rect, blendMode: CGBlendMode.normal, alpha: 1.0)
        UIGraphicsPopContext();
        
//        guard let imageReference = overlayImage.cgImage else { return }
//
//        let rect = self.rect(for: overlay.boundingMapRect)
//        ctx.scaleBy(x: 1.0, y: -1.0)
//        ctx.translateBy(x: 0.0, y: -rect.size.height)
//        ctx.draw(imageReference, in: rect)
    }

}



class FCViewController: UIViewController, MKMapViewDelegate {
    
    var locationManager: CLLocationManager!
    
    // for use to append discovered devices for 1 second
    var discoveredPeripheralsArr :[MyPeripheral] = []
    var last_time : TimeInterval = 0
    var region = "nus2"
    let deivce = "iphone"
    var sensorData = SensorData.init(region: "", begin_longitude: 0, begin_latitude: 0, end_longitude: 0, end_latitude: 0, device: "", sensor_data: [])
    var predictionData = PredictionData.init(region: "", device: "Iphone 6s", sensor_data: [])
    
    var discoveredBeacons: [IBeacon] = []
    
    var beaconLog = [[IBeacon]]()
    
    enum StartState {
        case INIT, STARTED
    }
    
    var state: StartState = .INIT
    
    var buildingId: Int = 0
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var pinImage: UIImageView!
    @IBOutlet weak var walkingBlink: UILabel!
    @IBOutlet weak var usePredictSwitch: UISwitch!
    @IBOutlet weak var predictLocationText: UILabel!
   
    let coords = CLLocationCoordinate2DMake(1.2965, 103.7805)
    let place = MKPlacemark(coordinate: CLLocationCoordinate2DMake(1.2965, 103.7805))
    // let centerLocation = mapView.centerCoordinate
    
    //MARK: - Floor Plan
    var fpImage = UIImage()
    
    var floorPlan: Floor!
    var floorPlanOverlay: MapOverlay? = nil
    var rotated = CGRect()
    var label = UILabel()

    var routeLine: MKPolyline? = nil
    var lineView: MKPolylineRenderer? = nil
    
    var UUIDString: [String] = []
    
    var buildingInfo: BuildingInfo!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(buildingId)
        
        APIService.shared.fetchBuildingInfo(id: buildingId) { (result) in
            guard let buildingInfo = result else {
                DispatchQueue.main.async {
                    self.showAlert(title: "Error", message: "Unable to fetch building with id \(self.buildingId)")
                }
                return
            }
            
            self.buildingInfo = buildingInfo
            
            self.setupBuildingData()
        }
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        walkingBlink.isHidden = true
        pinImage.alpha = 1
        // Do any additional setup after loading the view.
        // print(getCenterLocation(for: MKMapView))
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)

        mapView.delegate = self
        mapView.isPitchEnabled = false
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(beaconLog)
            let filePath = data.dataToFile(fileName: "output.txt")
            print(filePath)
        }
        catch (let err) {
            print(err)
        }

    }
    
    
    func setupBuildingData() {
        
        if buildingInfo.floors.count == 0 {
            self.showAlert(title: "Error", message: "No floor plan available")
        }
        
        let center = CLLocationCoordinate2D(latitude: buildingInfo.floors[0].center?.lat ?? 0, longitude: buildingInfo.floors[0].center?.lng ?? 0)
        
        self.floorPlan = buildingInfo.floors[0]
        
        self.region = buildingInfo.name
        
        self.predictionData.region = self.region
        
        self.sensorData.region = self.region
        
        fetchImage(with: "https://indoor.limandrew.org/\(floorPlan.url ?? "")")
        
        let region = MKCoordinateRegion(center: center, latitudinalMeters: 100, longitudinalMeters: 100)
        mapView.setRegion(region, animated: true)
        
        
        APIService.shared.fetchUUIDList(region: self.region) { (result) in
            self.UUIDString = result.uuid_list
            
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
                if CLLocationManager.isRangingAvailable() {
                    self.startScanning()
                }
            }
        }
        
        
    }
    
    // Fetches image with the given floorPlan
    func fetchImage(with url: String) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            let imageData = try? Data(contentsOf: URL(string: url)!)
            if (imageData == nil) {
                NSLog("Error fetching floor plan image")
            }
            // Bounce back to the main thread to update the UI
            DispatchQueue.main.async {
                self.fpImage = UIImage.init(data: imageData!)!
                self.changeMapOverlay()
            }
        }
    }
    
    // Function to change the map overlay
    func changeMapOverlay() {

        //Width and height in MapPoints for the floorplan
        let mapPointsPerMeter = MKMapPointsPerMeterAtLatitude(floorPlan.center?.lat ?? 0)
        let widthMapPoints = (Float(floorPlan.width ?? 0)) * Float(mapPointsPerMeter)
        let heightMapPoints = (Float(floorPlan.width ?? 0)) * Float(mapPointsPerMeter)

        let cgRect = CGRect(x: 0, y: 0, width: CGFloat(widthMapPoints), height: CGFloat(heightMapPoints))
        let a = degreesToRadians(self.floorPlan.bearing ?? 0)
        rotated = cgRect.applying(CGAffineTransform(rotationAngle: CGFloat(a)));
        floorPlanOverlay = MapOverlay(floorPlan: floorPlan, andRotatedRect: rotated)
        
        self.mapView.addOverlay(floorPlanOverlay!)
    }
    
    
    func confirmLocation(){
        let alert = UIAlertController(title: "Starting Location", message: "Is this the correct starting location? \n Begin X: \(mapView.centerCoordinate.longitude) \n Begin Y: \(mapView.centerCoordinate.latitude)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {[self]action in
            startStopButton.setTitle("STOP", for: .normal)
            state = .STARTED
            pinImage.alpha = 1
            discoveredPeripheralsArr.removeAll()
            startScanning()
            print("startscan")
            walkingBlink.blink()
            sensorData.begin_longitude = mapView.centerCoordinate.longitude
            sensorData.begin_latitude = mapView.centerCoordinate.latitude
            sensorData.sensor_data = []
            sensorData.device = "Iphone 6s"
            walkingBlink.isHidden = false

            
        }))
        
        self.present(alert, animated: true)
        
    }
    
    func polyline(){
        let locationOne = CLLocationCoordinate2D(latitude: sensorData.begin_latitude, longitude: sensorData.begin_longitude)
        let locationTwo = CLLocationCoordinate2D(latitude: sensorData.end_latitude, longitude: sensorData.end_longitude)
        
        let routeLine = MKPolyline(coordinates:[locationOne,locationTwo], count:2)
        
        self.mapView.addOverlay(routeLine)
    }
    
    @IBAction func startStopDidTab(_ any: UIButton) {
        switch state {
        case .INIT:
            confirmLocation()
        case .STARTED:
            handleMappingStop()
        }
    }
    
    @IBAction func goBtn(_ any: UIButton) {
        print("go button works")
        print(mapView.centerCoordinate)
        
        //        endLat = mapView.centerCoordinate.latitude
        //        endLong = mapView.centerCoordinate.longitude
        confirmLocation()
    }
    
    @IBAction func learnTapped(_ any: UIButton) {
        APIService.shared.triggerLearning(region: buildingInfo.name) { (result) in
            if (result) {
                DispatchQueue.main.async {
                    self.showAlert(title: "Success", message: "Started Learning.")
                }
            }
        }
    }
    
    
    func getCenterLocation(for mapView: MKMapView) -> CLLocation {
        
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }

    
    let annotation = MKPointAnnotation()
    
    func predictLocation() {
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
            
        let url = "http://137.132.165.14:8100/predict"

        let jsonData = try! encoder.encode(self.predictionData)
        
        print(String(data: jsonData, encoding: .utf8)!)
        
        predictionData.sensor_data = discoveredBeacons
        AF.request(url, method:.post, parameters: self.predictionData, encoder: JSONParameterEncoder.default).responseJSON { (response) in
            switch response.result {
            case .success(let json):
                print(json)
                
                // don't use force cast
                let myjson = json as! NSDictionary
                
                if (myjson["longitude"] != nil && myjson["latitude"] != nil) {
                    let coordinate = CLLocationCoordinate2D(latitude: myjson["latitude"] as! Double, longitude: myjson["longitude"] as! Double)
                    self.addLocationAnnotation(coordinate: coordinate)
                    self.predictLocationText.text = "\(String((myjson["latitude"] as! Double))), \(String((myjson["longitude"] as! Double))) "
                }
                
                break
            case .failure(let error):
                print("fail")
                print("error:\(error)")
                break
            }
        }
    }
    
    func addLocationAnnotation(coordinate: CLLocationCoordinate2D) {
        mapView.removeAnnotation(annotation)
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
    
    func postFingeprintData() {
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        print(self.sensorData)
        
        let jsonData = try! encoder.encode(sensorData)
        
        print(String(data: jsonData, encoding: .utf8)!)
        
        let url = "http://137.132.165.14:8100/addfootprints"
        AF.request(url, method: .post, parameters: self.sensorData, encoder: JSONParameterEncoder.default).responseString { (response) in
            switch response.result {
            case .success(let json) :
                print(json)
                self.sensorData.sensor_data.removeAll(keepingCapacity: true)
                break
            case . failure(let error):
                print("fail")
                // show alert here that mapping failed
                print("error:\(error)")
                break
                
            }
        }
    }
    
    func handleMappingStop() {
        
        startStopButton.setTitle("START", for: .normal)
        //select end location
        state = .INIT
        sensorData.end_longitude = mapView.centerCoordinate.longitude
        sensorData.end_latitude = mapView.centerCoordinate.latitude
        pinImage.alpha = 1
        print("stopScan")
        discoveredPeripheralsArr = []
        walkingBlink.stopBlink()
        walkingBlink.isHidden = true
        polyline()
        postFingeprintData()

    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = UIColor.blue
            polylineRenderer.lineWidth = 2
            return polylineRenderer
        }
        
        if overlay is MapOverlay {
            let overlayView = MapOverlayRenderer(overlay: overlay, overlayImage: fpImage, fp: floorPlan, rotated: rotated)
            return overlayView
        }
        
        //return nil
        return overlay as! MKOverlayRenderer
    }
}


extension FCViewController: CLLocationManagerDelegate {
    
    func startScanning() {
        
        self.UUIDString.append("fff8eac9-1a87-491b-99fd-6c875b5b246f")
        
        for uuidString in self.UUIDString {
            
            print("Starting monitoring for uuid: \(uuidString)")
            
            guard let uuid = UUID(uuidString: uuidString) else {continue}
            let constraint = CLBeaconIdentityConstraint(uuid: uuid)
            locationManager.startRangingBeacons(satisfying: constraint)
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
//        print(Date().timeIntervalSince1970)
//        print(beaconConstraint)
//        print(beacons)
        
        if beacons.count > 0 {
            discoveredBeacons = beacons.map({ (clBeacon: CLBeacon ) -> IBeacon in
                IBeacon(uuid: clBeacon.uuid.uuidString, major: Int(truncating: clBeacon.major), minor: Int(truncating: clBeacon.minor), rssi: clBeacon.rssi)
            })
            
            if state == .STARTED {
                self.sensorData.sensor_data.append(discoveredBeacons)
            }
            
            if usePredictSwitch.isOn {
                predictLocation()
            }
            
            beaconLog.append(discoveredBeacons)
        } else {
            print("no beacons")
        }
    }

}


extension UIViewController {
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func getDocumentsDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory as NSString
    }
}

extension Data {
    
    func getDocumentsDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory as NSString
    }

    /// Data into file
    ///
    /// - Parameters:
    ///   - fileName: the Name of the file you want to write
    /// - Returns: Returns the URL where the new file is located in NSURL
    func dataToFile(fileName: String) -> NSURL? {

        // Make a constant from the data
        let data = self

        // Make the file path (with the filename) where the file will be loacated after it is created
        let filePath = getDocumentsDirectory().appendingPathComponent(fileName)

        do {
            // Write the file from data into the filepath (if there will be an error, the code jumps to the catch block below)
            try data.write(to: URL(fileURLWithPath: filePath))

            // Returns the URL where the new file is located in NSURL
            return NSURL(fileURLWithPath: filePath)

        } catch {
            // Prints the localized description of the error from the do block
            print("Error writing the file: \(error.localizedDescription)")
        }

        // Returns nil if there was an error in the do-catch -block
        return nil

    }

}
