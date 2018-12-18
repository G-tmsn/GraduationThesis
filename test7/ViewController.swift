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
import AVFoundation

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    var myMapView: MKMapView!
    var myLocationManager: CLLocationManager!
    var audioPlayer: AVAudioPlayer!
    var timer: Timer!
    var count = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // タイマーを使って繰り返し
        timer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector:  #selector(self.misstakeDetecter(timer:)), userInfo: nil, repeats: true)
        timer.fire()
        
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
    
    var myTarget: CLLocationCoordinate2D!
    var lastAngle: Int!
    var nowAngle: Int!
    
    //======================================================================================================
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        timer.invalidate()
    }
    
    // GPSから値を取得した際に呼び出されるメソッド.
    func locationManager(_ manager: CLLocationManager/*, didUpdateLocations locations: [CLLocation]*/) {
        
        if(makingRouteNow == true){
            return
        }
        
        self.myLocationManager.stopUpdatingLocation()
        self.myLocationManager.startUpdatingLocation()
        
        print("didUpdateLocations")
        makingRouteNow = true
        
        // 既に生成しているルートを削除
        if(thereIsRoute == true){
            self.myMapView.removeOverlay(self.route.polyline)
            thereIsRoute = false
            print("Remove Route.")
        }
        
        // 配列から現在座標を取得.
        myLastLocation = myLocationManager.location
        // myLocations = locations as NSArray
        // myLastLocation = myLocations.lastObject as? CLLocation
        myLocation = myLastLocation.coordinate
        
        print("\(myLocation.latitude), \(myLocation.longitude)")
        
        // 目的地の緯度、経度を設定.
        requestLatitude = 35.7134
        requestLongitude = 139.7044
        // requestLatitude = 37.7758
        // requestLongitude = -122.4264
        
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
            }
            /*
            print(heading)
            
            if(self.thereIsRoute == true){
                var steps: [MKRoute.Step?]? { get {
                    return self.route!.steps
                    }
                }
                print(steps?.count)
                
                self.myMapView.addOverlay(self.route.steps[1].polyline)
            }*/
            
            // １つ目の曲がり角のと緯度軽度を取得
            self.myTarget = self.route.steps[1].polyline.coordinate
            
            // 1つ目の曲がり角の角度を取得
            if(self.thereIsRoute == true){
                
                self.lastAngle = self.nowAngle
                self.nowAngle = self.angle(currentLocation: self.myLocation, targetLocation: self.myTarget)
                if(self.lastAngle == nil){
                    self.lastAngle = self.nowAngle
                }
                // print(self.lastAngle)
                // print(self.nowAngle)
                
                // 角度が大きく変わっていたら音楽を流す
                if(self.angleChanged(previousAngle: self.lastAngle, nowAngle: self.nowAngle)){
                // if(self.lastAngle != self.nowAngle){
                    print("You are wrong")
                    self.playSound(name: "sound1")
                } else {
                    print("You are right")
                }
            }
        }
        
    }
    
    //==================================================================================================
    
    // 中継メソッド
    @objc func misstakeDetecter(timer: Timer) {
        
        count += 1
        if(count == 1){
            return
        }
        
        locationManager(myLocationManager)
    }
    
    // 方角を取得するメソッド
    func angle(currentLocation: CLLocationCoordinate2D, targetLocation: CLLocationCoordinate2D) -> Int {
        
        let currentLatitude = currentLocation.latitude
        let currentLongitude = currentLocation.longitude
        let targetLatitude = targetLocation.latitude
        let targetLongitude = targetLocation.longitude
        
        let difLongitude = targetLongitude - currentLongitude
        let y = sin(difLongitude)
        let x = cos(currentLatitude) * tan(targetLatitude) - sin(currentLatitude) * cos(difLongitude)
        let p = atan2(y, x) * 180 / Double.pi
        
        if p < 0 {
            return Int(360 + atan2(y, x) * 180 / Double.pi)
        }
        return Int(atan2(y, x) * 180 / Double.pi)
    }
    
    
    // 角度の差を計算するメソッド
    func angleChanged(previousAngle: Int, nowAngle: Int) -> Bool {
        
        // 2つの角度の差を計算
        let diff: Int = (previousAngle - nowAngle) % 360
        
        if(diff < 30){
            return false
        } else {
            return true
        }
    }
    
    //==================================================================================================
    
    
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


//======================================================================================================

// 音楽再生のための拡張クラス
extension ViewController: AVAudioPlayerDelegate {
    func playSound(name: String) {
        guard let path = Bundle.main.path(forResource: name, ofType: "wav") else {
            print("音源ファイルが見つかりません")
            return
        }
        
        do {
            // AVAudioPlayerのインスタンス化
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            
            // AVAudioPlayerのデリゲートをセット
            audioPlayer.delegate = self
            
            // 音声の再生
            audioPlayer.play()
        } catch {
        }
    }
}
