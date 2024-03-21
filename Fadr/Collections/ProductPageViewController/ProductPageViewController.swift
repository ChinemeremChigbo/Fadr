import UIKit
import CoreBluetooth
import SceneKit
import CoreMotion

class ProductPageViewController: UIViewController, CMHeadphoneMotionManagerDelegate, CBCentralManagerDelegate {
    var productObject: Product?

    var origin_quaternion = simd_quatf(ix: 0.7071068, iy: 0, iz: 0, r: 0.7071068)
    var new_origin_quaternion = simd_quatf(ix: 0.7071068, iy: 0, iz: 0, r: 0.7071068)
    var new_origin_set = false
    var first_quaternion = true
    let headphone = CMHeadphoneMotionManager()
    var headphoneData: CMDeviceMotion?
    let phone = CMMotionManager()
    var phoneData: CMDeviceMotion?
    
    var bluetooth = CBCentralManager()
    let serviceUUID = CBUUID(string: "ab0828b1-198e-4351-b779-901fa0e0371e")
    let peripheralName = "BLETest"
    var myPeripheral:CBPeripheral?
    var myCharacteristic:CBCharacteristic?
    
    var hairHeightNode: SCNNode!
    var lastUpdateTimestamp: TimeInterval = 0
    let updateInterval: TimeInterval = 0.1 // Adjust the update interval as needed
    var scnView = SCNView()
    
    lazy var colorLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()
    
    let resetOrientationButton = UIButton(type: .system)
    let connectClippersButton = UIButton(type: .system)
    
    
    func sendText(text: String) {
        if (myPeripheral != nil && myCharacteristic != nil) {
            let data = text.data(using: .utf8)
            myPeripheral!.writeValue(data!,  for: myCharacteristic!, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.name == peripheralName {
            myPeripheral = peripheral
            myPeripheral?.delegate = self
            bluetooth.connect(myPeripheral!, options: nil)
            bluetooth.stopScan()
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOff:
            print("Bluetooth is switched off")
        case .poweredOn:
            print("Bluetooth is switched on")
        case .unsupported:
            print("Bluetooth is not supported")
        default:
            print("Unknown state")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([serviceUUID])
        print("Connected to " +  peripheral.name!)
        connectClippersButton.setTitle("Connected", for: .normal)
        
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from " +  peripheral.name!)
        
        myPeripheral = nil
        myCharacteristic = nil
        
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print(error!)
    }
    
    func drawCircle() {
        // Get the middle point of the view
        let middlePoint = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        
        // Calculate the radius of the circle
        let radius: CGFloat = 5.0
        
        // Create a UIBezierPath for the circle
        let circlePath = UIBezierPath(arcCenter: middlePoint, radius: radius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        
        // Create a CAShapeLayer to draw the circle
        let circleLayer = CAShapeLayer()
        circleLayer.path = circlePath.cgPath
        circleLayer.strokeColor = UIColor.blue.cgColor // Set the stroke color to blue
        circleLayer.fillColor = UIColor.clear.cgColor // Set fill color to clear (transparent)
        circleLayer.lineWidth = 2.0 // Set the line width
        
        // Add the circle layer to the view's layer
        view.layer.addSublayer(circleLayer)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Simple 3D View"
        self.view.backgroundColor = .systemBackground
        headphone.delegate = self
        bluetooth.delegate = self
        
        
        SceneSetUp()
        
        drawCircle()
        
        guard headphone.isDeviceMotionAvailable else {
            AlertView.alert(self, "Sorry", "Your headphones are not supported.")
            return
        }
        
        guard phone.isDeviceMotionAvailable else {
            AlertView.alert(self, "Sorry", "Your phone is not supported.")
            return
        }
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 2
        
        headphone.startDeviceMotionUpdates(to: queue) { [weak self] motion, error in
            guard let motion = motion, error == nil else { return }
            self?.headphoneData = motion
            self?.processMotionDataIfNeeded()
        }
        
        phone.startDeviceMotionUpdates(to: queue) { [weak self] motion, error in
            guard let motion = motion, error == nil else { return }
            self?.phoneData = motion
            self?.processMotionDataIfNeeded()
        }
        
        resetOrientationButton.setTitle("Reset Orientation", for: .normal)
        resetOrientationButton.addTarget(self, action: #selector(resetOrientation), for: .touchUpInside)
        view.addSubview(resetOrientationButton)
        resetOrientationButton.translatesAutoresizingMaskIntoConstraints = false
        
        connectClippersButton.setTitle("Connect Clippers", for: .normal)
        connectClippersButton.addTarget(self, action: #selector(connectClippers), for: .touchUpInside)
        view.addSubview(connectClippersButton)
        connectClippersButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(colorLabel)
        
        NSLayoutConstraint.activate([
            colorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            colorLabel.bottomAnchor.constraint(equalTo: view.topAnchor, constant: 100),
            
            resetOrientationButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            resetOrientationButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            
            connectClippersButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            connectClippersButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50)
        ])
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.viewDidLoad()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        headphone.stopDeviceMotionUpdates()
        phone.stopDeviceMotionUpdates()
    }
    
    func processMotionDataIfNeeded() {
        let currentTimestamp = Date.timeIntervalSinceReferenceDate
        if currentTimestamp - lastUpdateTimestamp >= updateInterval {
            // Only process motion data if enough time has elapsed since the last update
            lastUpdateTimestamp = currentTimestamp
            DispatchQueue.main.async {
                self.NodeRotate()
                self.getColorOfMiddlePixelOfScene()
            }
        }
    }
    
    func NodeRotate() {
        guard let headphoneData = self.headphoneData, let phoneData = self.phoneData else {
            return
        }
        
        let headphone_quaternion = simd_quatd(ix: headphoneData.attitude.quaternion.x,
                                              iy: headphoneData.attitude.quaternion.z,
                                              iz: headphoneData.attitude.quaternion.y,
                                              r: -headphoneData.attitude.quaternion.w)
        
        let phone_quaternion = simd_quatd(ix: phoneData.attitude.quaternion.x,
                                          iy: phoneData.attitude.quaternion.z,
                                          iz: phoneData.attitude.quaternion.y,
                                          r: -phoneData.attitude.quaternion.w)
        
        let relative_quaternion = headphone_quaternion.inverse * phone_quaternion;
        let relative_quaternion_float = simd_quatf(ix: Float(relative_quaternion.vector.x),
                                                   iy: Float(relative_quaternion.vector.y),
                                                   iz: Float(relative_quaternion.vector.z),
                                                   r: Float(relative_quaternion.vector.w))
        if !new_origin_set {
            new_origin_quaternion = relative_quaternion_float
            new_origin_set = true
        }
        let rotation = new_origin_quaternion.inverse * relative_quaternion_float
        
        hairHeightNode?.simdOrientation =  origin_quaternion * rotation.inverse
        
    }
    @objc func resetOrientation() {
        new_origin_set = false
    }
    
    @objc func connectClippers() {
        print("Scanning")
        bluetooth.stopScan()
        connectClippersButton.setTitle("Scanning...", for: .normal)
        bluetooth.scanForPeripherals(withServices:[serviceUUID], options: nil)
    }
}

extension ProductPageViewController: CBPeripheralDelegate {
    
    func SceneSetUp() {
        self.scnView = SCNView(frame: self.view.frame)
        self.scnView.backgroundColor = UIColor.black
        self.scnView.allowsCameraControl = false
        self.scnView.showsStatistics = true
        view.addSubview(self.scnView)
        
        let scene = SCNScene()
        self.scnView.scene = scene
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zNear = 0.1
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 0.5)
        scene.rootNode.addChildNode(cameraNode)
        
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor.darkGray
        let ambientLightNode = SCNNode()
        ambientLightNode.light = ambientLight
        scene.rootNode.addChildNode(ambientLightNode)
        
        
        if let url = Bundle.main.url(forResource: "hair_height", withExtension: "scn") {
            if let loadedScene = try? SCNScene(url: url, options: nil) {
                for node in loadedScene.rootNode.childNodes as [SCNNode] {
                    scene.rootNode.addChildNode(node)
                    hairHeightNode = node
                }
            } else {
                print("Failed to create SCNScene from the .scn file.")
            }
        } else {
            print("Failed to load .scn file.")
        }
        
    }
    
    func getColorOfMiddlePixelOfScene(){
        
        let sceneImage = self.scnView.snapshot()
        
        let middleX = Int(sceneImage.size.width / 2)
        let middleY = Int(sceneImage.size.height / 2)
        
        guard let cgImage = sceneImage.cgImage else {
            return
        }
        let pixelData = cgImage.dataProvider?.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let pixelInfo: Int = ((Int(cgImage.width) * middleY) + middleX) * 4 // RGBA
        
        let red = CGFloat(data[pixelInfo]) / 255.0
        let height = String(format: "%.3f", Double(round(1000 * (1 - red)) / 1000))
        
        DispatchQueue.main.async {
            self.colorLabel.text = "Height: \(height)"
        }
        sendText(text:height)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        myCharacteristic = characteristics[0]
    }
    
}