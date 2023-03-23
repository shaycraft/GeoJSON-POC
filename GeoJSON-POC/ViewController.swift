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
    
    private func _setupMap() {
        //        let map = AGSMap(
        //            basemapStyle: .arcGISTopographic
        //        )
        
        let portal = AGSPortal.arcGISOnline(withLoginRequired: false)
        
        // TODO:  move to function
        // see https://developers.arcgis.com/ios/offline-maps-scenes-and-data/download-an-offline-map-ahead-of-time/ for the approach used here
        self.portalItem = AGSPortalItem(portal: portal, itemID: "ef722b2c44c2443090d98115a9ce8058")
        let map = AGSMap(item: portalItem!)
        map.load { (error) -> Void in
            self.mapView.map = map
            
            // self.offlineMapTask = AGSOfflineMapTask(portalItem: self.portalItem!)
            self.offlineMapTask = AGSOfflineMapTask(onlineMap: map)
            
            self.offlineMapTask?.getPreplannedMapAreas(completion: {[weak self] (mapAreas, error) in
                print("Hey!!!!!")
                if let error = error {
                    print("This is wack!!!!")
                    print(error.localizedDescription)
                } else {
                    print("Working...");
                    print(mapAreas as Any)
                }
            })
        }
        
        
        mapView.setViewpoint(
            AGSViewpoint(
                latitude: 34.02700,
                longitude: -118.80500,
                scale: 72_000
            )
        )
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
                //                 ##!  Idea!  add from geoJSON url (stored in s3), just as a straight layer using the S3 url
                //                ## But first, just try to shape it way they want with paths (see https://github.com/Esri/arcgis-runtime-samples-ios/blob/ee1bbe9b20a009770c12a3f2fb048edf552115e9/arcgis-ios-sdk-samples/Maps/Show%20location%20history/LocationHistoryViewController.swift)
            } else {
                print ("Json is BAD!!!!!")
            }
        }
        catch {
            print("Failed to load: \(error.localizedDescription)")
            print("Raw error is \(error)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _setupMap()
        _setupGrahpicsOverlay()
        
        _parseJsonAndAddToGraphics()
        
        // Do any additional setup after loading the view.
        
        //        //        let someString = "{'foo': 'bar'}"
        //        do {
        //            let myJsonObject = try JSONSerialization.jsonObject(with: sampleJsonResponse.data(using: .utf8)!) as? [String: Any]
        //            print (myJsonObject["spatialReference"])
        //        }
        //        catch {
        //            print("ERRORRRR!!!!")
        //            print("[DEBUG=====]: \(error)")
        //        }
        
        //        let str = "{\"names\": [\"Bob\", \"Tim\", \"Tina\"]}"
        //        let data = Data(sampleJsonResponse.utf8)
        //
        //        do {
        //            // make sure this JSON is in the format we expect
        //            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
        //                // try to read out a string array
        //                print(json["spatialReference"]!)
        //                if let names = json["names"] as? [String] {
        //                    print(names)
        //                }
        //            }
        //        } catch let error as NSError {
        //            print("Failed to load: \(error.localizedDescription)")
        //        }
    }
    
    
    
}

