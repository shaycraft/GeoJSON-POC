//
//  ViewController.swift
//  GeoJSON-POC
//
//  Created by Samuel Haycraft on 3/17/23.
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
    var portalItem: AGSPortalItem?
    var offlineMapTask: AGSOfflineMapTask?
    var preplannedParameters: AGSDownloadPreplannedOfflineMapParameters?
    private var downloadPreplannedMapJob: AGSDownloadPreplannedOfflineMapJob?
    
    private func _createOfflineMapJob(path: String, parameters: AGSDownloadPreplannedOfflineMapParameters) -> AGSDownloadPreplannedOfflineMapJob? {
        return self.offlineMapTask?.downloadPreplannedOfflineMapJob(with: parameters, downloadDirectory: URL(filePath: path))
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
                self?._printError(err: "parameteres object is null")
                return
            }
            
            
            if let parameters = parameters {
                parameters.continueOnErrors = false
                parameters.includeBasemap = true
                parameters.referenceBasemapDirectory = URL(filePath: "\\mytilepackages")
                self?.preplannedParameters = parameters
                
                print("parameters set")
                print(String(describing: self?.preplannedParameters))
                
                self?.downloadPreplannedMapJob = self?._createOfflineMapJob(path: "\\mydownloadmaps", parameters: parameters)
                guard self?.downloadPreplannedMapJob != nil else { return }
                
                print("DEBUG: map job = \(String(describing: self?.downloadPreplannedMapJob))")
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
    
    private func _setupMap() -> Void {
        let portal = AGSPortal.arcGISOnline(withLoginRequired: false)
        
        // TODO:  move to function
        // see https://developers.arcgis.com/ios/offline-maps-scenes-and-data/download-an-offline-map-ahead-of-time/ for the approach used here
        self.portalItem = AGSPortalItem(portal: portal, itemID: "ef722b2c44c2443090d98115a9ce8058")
        let map = AGSMap(item: portalItem!)
        map.load { (error) -> Void in
            self.mapView.map = map
            self.offlineMapTask = AGSOfflineMapTask(onlineMap: map)
            
            self._processMapAreaList(map: map)
            
            self.mapView.setViewpoint(
                AGSViewpoint(
                    latitude: 34.02700,
                    longitude: -118.80500,
                    scale: 72_000
                )
            )
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
            //            let data =  "{\"names\": [\"Bob\", \"Tim\", \"Tina\"]}"
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
        
        _setupMap()
        _setupGrahpicsOverlay()
        
        _parseJsonAndAddToGraphics()
    }
}
