import UIKit
import CoreBluetooth
import SceneKit
import CoreMotion

class ProductPageViewController: UIViewController, CMHeadphoneMotionManagerDelegate, CBCentralManagerDelegate {
    
    var productObject: Product?
    
    var starting_origin_quaternion = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)
    var reset_origin_quaternion = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)
    let default_quaternion = simd_quatf(ix:0, iy:0, iz:0, r:1)
    
    var reset_origin_quaternion_set = false
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
    let updateInterval: TimeInterval = 0.1
    var scnView = SCNView()
    
    
    
    lazy var heightLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    lazy var resetOrientationButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Reset", for: .normal)
        button.addTarget(self, action: #selector(resetOrientation), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        return button
    }()
    
    lazy var connectClippersButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Connect", for: .normal)
        button.addTarget(self, action: #selector(connectClippers), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        return button
    }()
    
    
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
        connectClippersButton.setTitle("Disconnect", for: .normal)
        connectClippersButton.removeTarget(self, action: #selector(connectClippers), for: .touchUpInside)
        connectClippersButton.addTarget(self, action: #selector(disconnectFromClippers), for: .touchUpInside)
        connectClippersButton.isEnabled = true
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from " +  peripheral.name!)
        connectClippersButton.setTitle("Connect", for: .normal)
        connectClippersButton.removeTarget(self, action: #selector(disconnectFromClippers), for: .touchUpInside)
        connectClippersButton.addTarget(self, action: #selector(connectClippers), for: .touchUpInside)
        connectClippersButton.isEnabled = true
        myPeripheral = nil
        myCharacteristic = nil
        
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print(error!)
        connectClippersButton.isEnabled = true
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
        circleLayer.strokeColor = UIColor.systemBlue.cgColor
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.lineWidth = 2.0 // Set the line width
        
        // Add the circle layer to the view's layer
        view.layer.addSublayer(circleLayer)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        
        view.addSubview(heightLabel)
        
        NSLayoutConstraint.activate([
            heightLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            heightLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
        ])
        
        
        view.addSubview(resetOrientationButton)
        
        // Set constraints for the reset button
        NSLayoutConstraint.activate([
            resetOrientationButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            resetOrientationButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),

        ])
        
        // Add the connect clippers button to the view
        view.addSubview(connectClippersButton)
        
        // Set constraints for the connect clippers button
        NSLayoutConstraint.activate([
            connectClippersButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            connectClippersButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
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
        
        let headphone_quaternion = self.headphoneData != nil ?
        simd_quatf(ix: Float(headphoneData!.attitude.quaternion.x),
                   iy: -Float(headphoneData!.attitude.quaternion.z),
                   iz: -Float(headphoneData!.attitude.quaternion.y),
                   r: Float(headphoneData!.attitude.quaternion.w)) :
        default_quaternion
        
        
        let phone_quaternion = self.phoneData != nil ?
        simd_quatf(ix: Float(phoneData!.attitude.quaternion.x),
                   iy: -Float(phoneData!.attitude.quaternion.z),
                   iz: -Float(phoneData!.attitude.quaternion.y),
                   r: Float(phoneData!.attitude.quaternion.w)) :
        default_quaternion
        
        
        let relative_quaternion = phone_quaternion * headphone_quaternion.inverse
        
        if !reset_origin_quaternion_set {
            reset_origin_quaternion = relative_quaternion
            reset_origin_quaternion_set = true
        }
        let rotation_quaternion = reset_origin_quaternion * relative_quaternion.inverse
        
        hairHeightNode.simdOrientation = starting_origin_quaternion * rotation_quaternion.inverse
        
    }
    @objc func resetOrientation() {
        reset_origin_quaternion_set = false
    }
    
    @objc func disconnectFromClippers() {
        if let peripheral = myPeripheral {
            bluetooth.cancelPeripheralConnection(peripheral)
            print("Disconnecting from " +  peripheral.name!)
            connectClippersButton.setTitle("Disconnecting...", for: .normal)
            connectClippersButton.isEnabled = false // Disable the button while disconnecting
            connectClippersButton.setTitleColor(.systemBlue, for: .normal)
        } else {
            print("No peripheral connected.")
        }
    }
    
    @objc func connectClippers() {
        print("Scanning")
        bluetooth.stopScan()
        connectClippersButton.setTitle("Scanning...", for: .normal)
        bluetooth.scanForPeripherals(withServices:[serviceUUID], options: nil)
        connectClippersButton.isEnabled = false // Disable the button while disconnecting
        connectClippersButton.setTitleColor(.systemBlue, for: .normal)
    }
}

extension ProductPageViewController: CBPeripheralDelegate {
    
    func SceneSetUp() {
        self.scnView = SCNView(frame: self.view.frame)
        self.scnView.backgroundColor = UIColor.systemBackground
        self.scnView.allowsCameraControl = false
        view.addSubview(self.scnView)
        
        // Load scene from file
        if let scene = SCNScene(named: "hair_height.scn") {
            self.scnView.scene = scene
            hairHeightNode = scene.rootNode.childNode(withName: "Head", recursively: true)
            
        } else {
            print("Failed to load scene from file")
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
        
        
        let inputValue = Double(round(1000 * (1 - red)) / 1000)
        let inputMin = 0.5
        let inputMax = 0.85
        let outputMin: Double = 700
        let outputMax: Double = 900
        
        let clampedValue = clamp(inputValue, inputMin, inputMax)
        let scaledValue = scale(clampedValue, inputMin, inputMax, outputMin, outputMax)
        
        let height = String(format: "%.3f", scaledValue)
        
        DispatchQueue.main.async {
            self.heightLabel.text = "Height: \(height)"
        }
        sendText(text:height)
    }
    
    private func clamp(_ value: Double, _ min: Double, _ max: Double) -> Double {
        return Swift.min(Swift.max(value, min), max)
    }
    
    private func scale(_ value: Double, _ inputMin: Double, _ inputMax: Double, _ outputMin: Double, _ outputMax: Double) -> Double {
        return ((value - inputMin) / (inputMax - inputMin)) * (outputMax - outputMin) + outputMin
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
