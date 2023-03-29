//
//  ViewController.swift
//  GeoJSON-POC
//
//  Created by Samuel Haycraft on 3/17/23.
//  TODO: convert callback hell to async pattern
//  see https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/
//

import UIKit

import ArcGIS

let geoJSONTest = """
{
    "exceededTransferLimit": true,
    "features": [
        {
            "geometry": {
                "coordinates": [
                    -88.17867628561726,
                    41.769261584458384
                ],
                "type": "Point"
            },
            "id": 1,
            "properties": {
                "activeflag": 0,
                "enabled": 1,
                "facilityid": "36199",
                "installdate": -2208988800000,
                "lasteditor": "ESRI",
                "lastservice": 1217894400000,
                "lastupdate": 1271761435000,
                "locdesc": "test",
                "maintby": 1,
                "manufacturer": "Waterous",
                "objectid": 1,
                "operable": 2,
                "ownedby": 1,
                "rotation": null
            },
            "type": "Feature"
        }
    ],
    "properties": {
        "exceededTransferLimit": true
    },
    "type": "FeatureCollection"
}
"""

let pathsArrayTest = """
{
    "paths": [[
        [-88.17867628561726,41.769261584458384]
    ]],
    "spatialReference":{"wkid":4326,"latestWkid":4326}
}
"""

let pathsPointDumeTest = """
{
    "paths": [[
        [
            -118.81667331915597,
            34.023707184994876
        ],
        [
            -118.81043022035571,
            34.0217894089088
        ],
        [
            -118.80126203330639,
            34.017012872562674
        ],
        [
            -118.80165495560846,
            34.01180179910021
        ]
    ]],
    "spatialReference":{"wkid":4326,"latestWkid":4326}
}
"""

class ViewController: UIViewController {
    @IBOutlet weak var mapView: AGSMapView!
    var graphicsOverlay: AGSGraphicsOverlay! = AGSGraphicsOverlay()
    var offlineMapTask: AGSOfflineMapTask?
    var preplannedParameters: AGSDownloadPreplannedOfflineMapParameters?
    
    private var downloadPreplannedMapJob: AGSDownloadPreplannedOfflineMapJob?
    
    // download directories
    private var downloadDirectoryMap: URL?
    
    private func _createDownloadDirectories() throws -> Void {
        self.downloadDirectoryMap = try self._createTemporaryDirectory(directoryName: "GIS_DOWNLOAD_MAP_DATA")
    }
    
    private func _createTemporaryDirectory(directoryName: String) throws -> URL? {
        let defaultManager = FileManager.default
        let temporaryDownloadURL = defaultManager.temporaryDirectory.appendingPathComponent(directoryName)
        
        if defaultManager.fileExists(atPath: temporaryDownloadURL.path) {
            try defaultManager.removeItem(atPath: temporaryDownloadURL.path)
        }
        try  defaultManager.createDirectory(at: temporaryDownloadURL, withIntermediateDirectories: true, attributes: nil)
        
        print( String(describing: defaultManager.subpaths(atPath: FileManager.default.temporaryDirectory.path)))
        
        return temporaryDownloadURL
    }
    
    private func _getMapId() -> String {
        // trailheads sample data from tutorial
            return "ef722b2c44c2443090d98115a9ce8058"
        // TIGER census data roads/waters sample (Colorado)
        //    private var MAP_PORTAL_ID: String! = "48045b4e68af4dfe87c8765bfee4a954"
        // Xcel example on prem portal (dev region)
        //    private let MAP_PORTAL_ID: String! = "31f6634899e24180a43e5fa994e69ec5"
        // Xcel example on prem portal (gdl-tst)
//        return "d45931415e4141cf8e18851980127176"
    }
    
    private func _runDownloadMapJob() -> Void {
        self.downloadPreplannedMapJob?.start(statusHandler: { [weak self] (status) in
            let normalizedFraction = (self?.downloadPreplannedMapJob!.progress.fractionCompleted)! * 100
            let percentComplete: String = String(format: "%.0f", normalizedFraction)
            
            print("Status [\(percentComplete) % complete...]: \(status)")
        }, completion: { (result, error) in
            print("File download completed")
            if let error = error {
                self._printError(err: "Error occurred in download map job completion")
                print(error.localizedDescription)
                print(error)
            }
            
            guard let result = result else { return }
            
            if result.hasErrors {
                self._printError(err: "result of download offline map has errors")
            } else {
                print("Downloaded data info ...")
                print(String(describing: result.mobileMapPackage))
                print(self.downloadDirectoryMap!.path)
                self.mapView.map = result.offlineMap
            }
            
        })
    }
    
    private func _instantiateDownloadJobObject(parameters: AGSDownloadPreplannedOfflineMapParameters) -> AGSDownloadPreplannedOfflineMapJob? {
        return self.offlineMapTask?.downloadPreplannedOfflineMapJob(with: parameters, downloadDirectory: self.downloadDirectoryMap!)
    }
    
    private func _createOfflineMapJob(mapArea: AGSPreplannedMapArea) -> Void {
        print("We are in process map area now \(mapArea)")
        
        self.offlineMapTask?.defaultDownloadPreplannedOfflineMapParameters(with: mapArea, completion: {[weak self] (parameters, error) in
            if let error = error {
                self?._printError(err: "Error returned in download parameters")
                print(error.localizedDescription)
                return
            }
            
            guard parameters != nil else {
                self?._printError(err: "parameters object is null")
                return
            }
            
            
            if let parameters = parameters {
                parameters.continueOnErrors = false
                parameters.includeBasemap = true
                self?.preplannedParameters = parameters
                
                print("parameters set")
                print(String(describing: self?.preplannedParameters))
                
                self?.downloadPreplannedMapJob = self?._instantiateDownloadJobObject(parameters: parameters)
                guard self?.downloadPreplannedMapJob != nil else { return }
                
                print("DEBUG: map job = \(String(describing: self?.downloadPreplannedMapJob))")
                
                self?._runDownloadMapJob()
            }
        })
    }
    
    private func _processMapAreaList(map: AGSMap) -> Void {
        self.offlineMapTask?.getPreplannedMapAreas(completion: { [weak self] (mapAreas, error) in
            if let error = error {
                self?._printError(err:  "GetPrePlannedMapAreas failed")
                print(error.localizedDescription)
            }
            print("Map areas = \(String(describing:mapAreas))")
            
            guard mapAreas != nil else {
                self?._printError(err: "No map areas returned in list")
                return
            }
            
            if let mapAreas = mapAreas {
                self?._createOfflineMapJob(mapArea: mapAreas[0])
            }
        })
    }
    
    private func _initPortalWithMap(mapId: String, useArcGisOnline: Bool) -> AGSMap {
        var portal: AGSPortal
        
        if (useArcGisOnline == true) {
            portal = AGSPortal.arcGISOnline(withLoginRequired: false)
        } else {
            portal = AGSPortal(url: URL(string: "https://oa9sars9w5.execute-api.us-east-2.amazonaws.com/arcgis/home")!, loginRequired: false)
        }
        
        return AGSMap(item: AGSPortalItem(portal: portal, itemID: mapId))
    }
    
    private func _setupMap() -> Void {
        
//        self.portalItem = AGSPortalItem(portal: portal, itemID: self.MAP_PORTAL_ID)
//        let map = AGSMap(item: portalItem!)
        let map = self._initPortalWithMap(mapId: self._getMapId(), useArcGisOnline: true)
        
        map.load { error -> Void in
            if let error = error {
                print("There was an error in map load!!!!!!")
                print(error.localizedDescription)
                exit(1)
            }
            
            self.mapView.map = map
            
            let dummyLayer: AGSFeatureLayer = map.operationalLayers[0] as! AGSFeatureLayer
            let dummyPortalItem: AGSPortalItem = dummyLayer.item as! AGSPortalItem
            print("Item id from portal is \(dummyPortalItem.itemID)")
            // print(map.operationalLayers)
            
             self.offlineMapTask = AGSOfflineMapTask(onlineMap: map)
             self._processMapAreaList(map: map)
            
            // Denver
            // let lat = 39.735523
            // let long = -104.983407
            // let scale = 72_000
            
            // California
            let lat = 34.02700
            let long = -118.80500
            let scale: Double = 72_000
            
            let viewPoint = AGSViewpoint(
                latitude: lat,
                longitude: long,
                scale: scale
            )
            self.mapView.setViewpoint(viewPoint)
        }
    }
    
    private func _printError(err: Any) {
        print(">>>>>>> ERROR: \(err) <<<<<<<")
    }
    
    private func _setupGrahpicsOverlay() {
        mapView.graphicsOverlays.add(graphicsOverlay!)
    }
    
    private func _parseJsonAndAddToGraphics() {
        do {
            if let json = try JSONSerialization.jsonObject(with: Data(pathsPointDumeTest.utf8)) as? [String: Any] {
                print("Json is good")
                let polyline = try AGSPolyline.fromJSON(json)
                let polylineSymbol = AGSSimpleLineSymbol(style: .solid, color: .blue, width: 3.0)
                let polylineGraphic = AGSGraphic(geometry: polyline as? AGSGeometry, symbol: polylineSymbol)
                graphicsOverlay.graphics.add(polylineGraphic)
                print(polyline)
            } else {
                self._printError(err: "JSON parse failed")
            }
        }
        catch {
            self._printError(err: "Failed to load: \(error.localizedDescription)")
            self._printError(err: "Raw error is \(error)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        // create download directories
        do {
            try self._createDownloadDirectories()
        }
        catch {
            self._printError(err: "Problem occurred creating temorary directories...")
            print(error)
        }
        
        _setupMap()
        // _setupGrahpicsOverlay()
        // _parseJsonAndAddToGraphics()
    }
}
