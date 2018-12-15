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
    //var timer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // タイマーを使って繰り返し
        /*timer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector:  #selector(self.locationManager), userInfo: nil, repeats: true)
        timer.fire()*/
        
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
        myLocationManager.startUpdatingHeading()
        
        // MapViewの生成.
        myMapView = MKMapView()
        
        // MapViewのサイズを画面全体に
        myMapView.frame = self.view.bounds
        
        // Delegateを設定.
        myMapView.delegate = self
        
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
        myMapView.userTrackingMode = MKUserTrackingMode.followWithHeading
        
    }
    
    //======================================================================================================
    
    // 配列から現在座標を取得
    var myLocations: NSArray = []
    var myLastLocation: CLLocation!
    var myLocation:CLLocationCoordinate2D!
    
    // 目的地の緯度、経度を設定
    var requestLatitude: CLLocationDegrees!
    var requestLongitude: CLLocationDegrees!
    
    // 目的地の座標を指定.
    var requestCoordinate: CLLocationCoordinate2D!
    var fromCoordinate: CLLocationCoordinate2D!
    
    // PlaceMarkを生成して出発点、目的地の座標をセット.
    var fromPlace: MKPlacemark!
    var toPlace: MKPlacemark!
    
    // Itemを生成してPlaceMarkをセット.
    var fromItem: MKMapItem!
    var toItem: MKMapItem!
    
    // MKDirectionsRequestを生成.
    var myRequest: MKDirections.Request!
    
    // MKDirectionsを生成してRequestをセット.
    var myDirections: MKDirections!
    
    // ピンを生成.
    // let fromPin: MKPointAnnotation = MKPointAnnotation()
    var toPin: MKPointAnnotation!
    
    var thereIsRoute: Bool = false
    var makingRouteNow: Bool = false
    
    var route: MKRoute!
    
    //======================================================================================================
    
    /*override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        timer.invalidate()
    }*/
    
    // GPSから値を取得した際に呼び出されるメソッド.
    @objc func locationManager(_ manager: CLLocationManager, /*timer: Timer, */didUpdateLocations locations: [CLLocation]) {
        
        while true {
        
        if(makingRouteNow == true){
            return
        }
        
        print("didUpdateLocations")
        makingRouteNow = true
        
        // 既に生成しているルートを削除
        if(thereIsRoute == true){
            self.myMapView.removeOverlay(self.route.polyline)
            thereIsRoute = false
            print("Remove Route.")
        }
        
        // 配列から現在座標を取得.
        myLocations = locations as NSArray
        myLastLocation = myLocations.lastObject as? CLLocation
        myLocation = myLastLocation.coordinate
        
        print("\(myLocation.latitude), \(myLocation.longitude)")
        
        // 目的地の緯度、経度を設定.
        requestLatitude = 35.7134
        requestLongitude = 139.7044
        
        // 目的地の座標を指定.
        requestCoordinate = CLLocationCoordinate2DMake(requestLatitude, requestLongitude)
        //let fromCoordinate = CLLocationCoordinate2DMake(myLatitude, myLongitude)
        fromCoordinate = myLocation
        
        // PlaceMarkを生成して出発点、目的地の座標をセット.
        fromPlace = MKPlacemark(coordinate: fromCoordinate, addressDictionary: nil)
        toPlace = MKPlacemark(coordinate: requestCoordinate, addressDictionary: nil)
        
        // Itemを生成してPlaceMarkをセット.
        fromItem = MKMapItem(placemark: fromPlace)
        toItem = MKMapItem(placemark: toPlace)
        
        // MKDirectionsRequestを生成.
        myRequest = MKDirections.Request()
        
        // 出発地のItemをセット.
        myRequest.source = fromItem
        
        // 目的地のItemをセット.
        myRequest.destination = toItem
        
        // 複数経路の検索を有効.
        myRequest.requestsAlternateRoutes = true
        
        // 移動手段を徒歩に設定.
        myRequest.transportType = MKDirectionsTransportType.walking
        
        // MKDirectionsを生成してRequestをセット.
        myDirections = MKDirections(request: myRequest)
        
        // 経路探索.
        myDirections.calculate { (response, error) in
            
            // NSErrorを受け取ったか、ルートがない場合.
            if error != nil || response!.routes.isEmpty {
                return
            }
            
            self.route = response!.routes[0] as MKRoute
            print("目的地まで \(self.route.distance)km")
            print("所要時間 \(Int(self.route.expectedTravelTime/60))分")
            
            // mapViewにルートを描画.
            self.myMapView.addOverlay(self.route.polyline)
            
            // ピンを生成.
            // let fromPin: MKPointAnnotation = MKPointAnnotation()
            self.toPin = MKPointAnnotation()
            
            // 座標をセット.
            // fromPin.coordinate = fromCoordinate
            self.toPin.coordinate = self.requestCoordinate
            
            // titleをセット.
            // fromPin.title = "出発地点"
            self.toPin.title = "目的地"
            
            // mapViewに追加.
            // self.myMapView.addAnnotation(fromPin)
            self.myMapView.addAnnotation(self.toPin)
            
            self.thereIsRoute = true
            print("madeAnnotation")
            self.makingRouteNow = false
            
            // ユーザーの方向を取得
            var heading: CLHeading? { get {
                return self.myLocationManager.heading
                }
            }/*
            print(heading)
            
            if(self.thereIsRoute == true){
                var steps: [MKRoute.Step?]? { get {
                    return self.route!.steps
                    }
                }
                print(steps?.count)
                
                self.myMapView.addOverlay(self.route.steps[1].polyline)
            }*/
        }
            Thread.sleep(forTimeInterval: 3.0)
        }
        
    }
    
    //======================================================================================================
 /*
    // Regionが変更した時に呼び出されるメソッド
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool, didUpdateLocations locations: [CLLocation]) {
        print("regionDidChangeAnimated")
        self.myMapView.removeOverlay(toPin as! MKOverlay)
        
        // 既に生成しているルートを削除
        if(thereIsRoute == true){
            self.myMapView.removeAnnotation(toPin)
            thereIsRoute = false
        }
        
        // 配列から現在座標を取得.
        myLocations = locations as NSArray
        myLastLocation = myLocations.lastObject as? CLLocation
        myLocation = myLastLocation.coordinate
        
        print("\(myLocation.latitude), \(myLocation.longitude)")
        
        // 目的地の緯度、経度を設定.
        requestLatitude = 35.7134
        requestLongitude = 139.7044
        
        // 目的地の座標を指定.
        requestCoordinate = CLLocationCoordinate2DMake(requestLatitude, requestLongitude)
        //let fromCoordinate = CLLocationCoordinate2DMake(myLatitude, myLongitude)
        fromCoordinate = myLocation
        
        // PlaceMarkを生成して出発点、目的地の座標をセット.
        fromPlace = MKPlacemark(coordinate: fromCoordinate, addressDictionary: nil)
        toPlace = MKPlacemark(coordinate: requestCoordinate, addressDictionary: nil)
        
        
        // Itemを生成してPlaceMarkをセット.
        fromItem = MKMapItem(placemark: fromPlace)
        toItem = MKMapItem(placemark: toPlace)
        
        // MKDirectionsRequestを生成.
        myRequest = MKDirections.Request()
        
        // 出発地のItemをセット.
        myRequest.source = fromItem
        
        // 目的地のItemをセット.
        myRequest.destination = toItem
        
        // 複数経路の検索を有効.
        myRequest.requestsAlternateRoutes = true
        
        // 移動手段を徒歩に設定.
        myRequest.transportType = MKDirectionsTransportType.walking
        
        // MKDirectionsを生成してRequestをセット.
        myDirections = MKDirections(request: myRequest)
        
        myDirections.calculate { (response, error) in
            
            // NSErrorを受け取ったか、ルートがない場合.
            if error != nil || response!.routes.isEmpty {
                return
            }
            
            let route: MKRoute = response!.routes[0] as MKRoute
            print("目的地までぇ \(route.distance)km")
            print("所要時間 \(Int(route.expectedTravelTime/60))分")
            
            // mapViewにルートを描画.
            self.myMapView.addOverlay(route.polyline)
            
            // ピンを生成.
            // let fromPin: MKPointAnnotation = MKPointAnnotation()
            self.toPin = MKPointAnnotation()
            
            // 座標をセット.
            // fromPin.coordinate = fromCoordinate
            self.toPin.coordinate = self.requestCoordinate
            
            // titleをセット.
            // fromPin.title = "出発地点"
            self.toPin.title = "目的地"
            
            // mapViewに追加.
            // self.myMapView.addAnnotation(fromPin)
            self.myMapView.addAnnotation(self.toPin)
            self.thereIsRoute = true
        }
    }
    */
    //======================================================================================================
    
    
    
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
        routeRenderer.lineWidth = 5.0
        
        // ルートの線の色.
        routeRenderer.strokeColor = UIColor.init(displayP3Red: 0.2, green: 0.2, blue: 1, alpha: 0.8)
        return routeRenderer
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
