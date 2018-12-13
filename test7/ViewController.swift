//
//  ViewController.swift
//  test7
//
//  Created by 塚本賢治 on 2018/12/11.
//  Copyright © 2018年 塚本賢治. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    var myMapView: MKMapView!
    var myLocationManager: CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // LocationManagerの生成.
        myLocationManager = CLLocationManager()
        
        // Delegateの設定.
        myLocationManager.delegate = self
        
        // 距離のフィルタ.
        myLocationManager.distanceFilter = 100.0
        
        // 精度.
        myLocationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        
        // セキュリティ認証のステータスを取得.
        let status = CLLocationManager.authorizationStatus()
        
        // まだ認証が得られていない場合は、認証ダイアログを表示.
        if(status != CLAuthorizationStatus.authorizedWhenInUse) {
            
            print("not determined")
            // まだ承認が得られていない場合は、認証ダイアログを表示.
            myLocationManager.requestWhenInUseAuthorization()
        }
        
        // 位置情報の更新を開始.
        myLocationManager.startUpdatingLocation()
        
        // MapViewの生成.
        myMapView = MKMapView()
        
        // MapViewのサイズを画面全体に
        myMapView.frame = self.view.bounds
        
        // Delegateを設定.
        myMapView.delegate = self
        
        // 方向も示すように設定
        // myMapView.setUserTrackingMode(MKUserTrackingMode.followWithHeading, animated: true)
        
        // MapViewをViewに追加.
        self.view.addSubview(myMapView)
        
        // 中心点の緯度経度.
        let myLat: CLLocationDegrees = 37.506804
        let myLon: CLLocationDegrees = 139.930531
        let myCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(myLat, myLon) as CLLocationCoordinate2D
        
        // 縮尺.
        let myLatDist : CLLocationDistance = 100
        let myLonDist : CLLocationDistance = 100
        
        // Regionを作成.
        let myRegion: MKCoordinateRegion = MKCoordinateRegion(center: myCoordinate, latitudinalMeters: myLatDist, longitudinalMeters: myLonDist);
        
        // MapViewに反映
        myMapView.setRegion(myRegion, animated: true)
        
        //位置に追従する
        myMapView.userTrackingMode = MKUserTrackingMode.follow

        
    }
    
    // GPSから値を取得した際に呼び出されるメソッド.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        print("didUpdateLocations")
        
        // 配列から現在座標を取得.
        let myLocations: NSArray = locations as NSArray
        let myLastLocation: CLLocation = myLocations.lastObject as! CLLocation
        let myLocation:CLLocationCoordinate2D = myLastLocation.coordinate
        
        print("\(myLocation.latitude), \(myLocation.longitude)")
        
        // 目的地の緯度、経度を設定.
        let requestLatitude: CLLocationDegrees = 35.7134
        let requestLongitude: CLLocationDegrees = 139.7044
        
        // 目的地の座標を指定.
        let requestCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(requestLatitude, requestLongitude)
        //let fromCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(myLatitude, myLongitude)
        let fromCoordinate: CLLocationCoordinate2D = myLocation
        
        // PlaceMarkを生成して出発点、目的地の座標をセット.
        let fromPlace: MKPlacemark = MKPlacemark(coordinate: fromCoordinate, addressDictionary: nil)
        let toPlace: MKPlacemark = MKPlacemark(coordinate: requestCoordinate, addressDictionary: nil)
        
        
        // Itemを生成してPlaceMarkをセット.
        let fromItem: MKMapItem = MKMapItem(placemark: fromPlace)
        let toItem: MKMapItem = MKMapItem(placemark: toPlace)
        
        // MKDirectionsRequestを生成.
        let myRequest: MKDirections.Request = MKDirections.Request()
        
        // 出発地のItemをセット.
        myRequest.source = fromItem
        
        // 目的地のItemをセット.
        myRequest.destination = toItem
        
        // 複数経路の検索を有効.
        myRequest.requestsAlternateRoutes = true
        
        // 移動手段を徒歩に設定.
        myRequest.transportType = MKDirectionsTransportType.walking
        
        // MKDirectionsを生成してRequestをセット.
        let myDirections: MKDirections = MKDirections(request: myRequest)
        
        // 経路探索.
        myDirections.calculate { (response, error) in
            
            // NSErrorを受け取ったか、ルートがない場合.
            if error != nil || response!.routes.isEmpty {
                return
            }
            
            let route: MKRoute = response!.routes[0] as MKRoute
            print("目的地まで \(route.distance)km")
            print("所要時間 \(Int(route.expectedTravelTime/60))分")
            
            // mapViewにルートを描画.
            self.myMapView.addOverlay(route.polyline)
            
            // ピンを生成.
            // let fromPin: MKPointAnnotation = MKPointAnnotation()
            let toPin: MKPointAnnotation = MKPointAnnotation()
            
            // 座標をセット.
            // fromPin.coordinate = fromCoordinate
            toPin.coordinate = requestCoordinate
            
            // titleをセット.
            // fromPin.title = "出発地点"
            toPin.title = "目的地"
            
            // mapViewに追加.
            // self.myMapView.addAnnotation(fromPin)
            self.myMapView.addAnnotation(toPin)
            
        }
        
    }
 
    // Regionが変更した時に呼び出されるメソッド.
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("regionDidChangeAnimated")
    }
    
    // 認証が変更された時に呼び出されるメソッド.
    private func mylocationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status{
        case .authorizedWhenInUse:
            print("AuthorizedWhenInUse")
        case .authorized:
            print("Authorized")
        case .denied:
            print("Denied")
        case .restricted:
            print("Restricted")
        case .notDetermined:
            print("NotDetermined")
        case .authorizedAlways:
            print("banana")
        }
    }
    
    // ルートの表示設定.
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let route: MKPolyline = overlay as! MKPolyline
        let routeRenderer: MKPolylineRenderer = MKPolylineRenderer(polyline: route)
        
        // ルートの線の太さ.
        routeRenderer.lineWidth = 3.0
        
        // ルートの線の色.
        routeRenderer.strokeColor = UIColor.red
        return routeRenderer
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
