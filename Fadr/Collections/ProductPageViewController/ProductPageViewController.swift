import UIKit
import CoreBluetooth
import SceneKit
import CoreMotion


var isModalOpen = false

class ProductPageViewController: UIViewController, CMHeadphoneMotionManagerDelegate, CBCentralManagerDelegate {
    
    var productObject: Product?
    
    var slider: CustomSlider!
    var alertController: UIAlertController?
    var minLabel: UILabel!
    var maxLabel: UILabel!

    
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
        
    var outputMin: Float = 0
    var outputMax: Float = 180
    
    var ticksPerMm: Float = 18
    
    
    lazy var heightLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15)
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
    
    @objc func resetOrientation() {
        reset_origin_quaternion_set = false
    }
    
    lazy var connectClippersButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Connect", for: .normal)
        button.addTarget(self, action: #selector(connectClippers), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        return button
    }()
    
    @objc func connectClippers() {
        print("Scanning")
        bluetooth.stopScan()
        connectClippersButton.setTitle("Scanning...", for: .normal)
        bluetooth.scanForPeripherals(withServices:[serviceUUID], options: nil)
        connectClippersButton.isEnabled = false // Disable the button while disconnecting
        connectClippersButton.setTitleColor(.systemBlue, for: .normal)
    }
    
    @objc func disconnectClippers() {
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
    
    lazy var informationButton: UIButton = {
        let button = UIButton(type: .infoLight)
        button.addTarget(self, action: #selector(showInformationModal), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    

    @objc func showInformationModal() {
        isModalOpen = true

        // Create UIAlertController
        alertController = UIAlertController(title: "Information", message: "\n\n\n\n\n\n\n\n\n\n\n", preferredStyle: .alert)
        // Add text fields for minimum and maximum values
        alertController?.addTextField { textField in
            textField.placeholder = "Minimum Value"
            textField.text = "\(self.outputMin)"
            textField.keyboardType = .decimalPad
        }
        
        alertController?.addTextField { textField in
            textField.placeholder = "Maximum Value"
            textField.text = "\(self.outputMax)"
            textField.keyboardType = .decimalPad
        }
        
        // Add a text field for "Ticks per mm"
        alertController?.addTextField { textField in
            textField.placeholder = "Ticks per mm"
            textField.text = "\(self.ticksPerMm)"
            textField.keyboardType = .decimalPad
        }
        
        
        // Create segmented control for choosing control type
        let controlTypeSegmentedControl = UISegmentedControl(items: ["Servo", "Linear Actuator"])
        controlTypeSegmentedControl.selectedSegmentIndex = 0 // Default selection: Servo
        alertController?.view.addSubview(controlTypeSegmentedControl)
        
        // Create slider
        self.slider = CustomSlider(frame: CGRect(x: 10, y: 70, width: 250, height: 20))
        self.slider.minimumValue = self.outputMin
        self.slider.maximumValue = self.outputMax
        self.slider.value = (self.outputMin + self.outputMax) / 2
        alertController?.view.addSubview(self.slider)
        
        // Create labels for displaying min and max values
        minLabel = UILabel(frame: CGRect(x: 10, y: 150, width: 50, height: 20))
        minLabel.text = "\(self.outputMin)"
        minLabel.textAlignment = .center
        alertController?.view.addSubview(minLabel)
        
        maxLabel = UILabel(frame: CGRect(x: 210, y: 150, width: 50, height: 20))
        maxLabel.text = "\(self.outputMax)"
        maxLabel.textAlignment = .center
        alertController?.view.addSubview(maxLabel)
        
        // Create Save button
        let saveButton = UIButton(type: .system)
        saveButton.setTitle("Save", for: .normal)
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        alertController?.view.addSubview(saveButton)
        
        // Create Zero button
        let zeroButton = UIButton(type: .system)
        zeroButton.setTitle("Zero", for: .normal)
        zeroButton.addTarget(self, action: #selector(zeroButtonTapped), for: .touchUpInside)
        alertController?.view.addSubview(zeroButton)
        
        // Add target to segmented control to detect changes
        controlTypeSegmentedControl.addTarget(self, action: #selector(controlTypeChanged(_:)), for: .valueChanged)
        
        // Add OK button
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            guard let minText = self.alertController?.textFields?[0].text,
                  let maxText = self.alertController?.textFields?[1].text,
                  let ticksPerMmText = self.alertController?.textFields?[2].text,
                  let minValue = Float(minText),
                  let maxValue = Float(maxText),
                  let ticksPerMmValue = Float(ticksPerMmText) else {
                return
            }
            
            guard minValue <= maxValue else {
                // Show an error alert
                let errorAlert = UIAlertController(title: "Error", message: "Minimum value cannot be larger than maximum value.", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(errorAlert, animated: true, completion: nil)
                return
            }
            
            isModalOpen = false

            self.outputMin = minValue
            self.outputMax = maxValue
            self.ticksPerMm = ticksPerMmValue
            
            self.slider.minimumValue = minValue
            self.slider.maximumValue = maxValue
            self.slider.value = (minValue + maxValue) / 2
        }
        
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            isModalOpen = false
        }
        
        alertController?.addAction(okAction)
        alertController?.addAction(cancelAction)

        // Set up constraints
        controlTypeSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        self.slider.translatesAutoresizingMaskIntoConstraints = false
        minLabel.translatesAutoresizingMaskIntoConstraints = false
        maxLabel.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        zeroButton.translatesAutoresizingMaskIntoConstraints = false


        NSLayoutConstraint.activate([
            controlTypeSegmentedControl.topAnchor.constraint(equalTo: alertController!.view.topAnchor, constant: 80),
            controlTypeSegmentedControl.topAnchor.constraint(equalTo: alertController!.view.topAnchor, constant: 80),
            controlTypeSegmentedControl.centerXAnchor.constraint(equalTo: alertController!.view.centerXAnchor),
            self.slider.topAnchor.constraint(equalTo: controlTypeSegmentedControl.bottomAnchor, constant: 20),
            self.slider.leadingAnchor.constraint(equalTo: alertController!.view.leadingAnchor, constant: 20),
            self.slider.trailingAnchor.constraint(equalTo: alertController!.view.trailingAnchor, constant: -20),
            minLabel.topAnchor.constraint(equalTo: self.slider.bottomAnchor, constant: 10),
            minLabel.leadingAnchor.constraint(equalTo: self.slider.leadingAnchor),
            maxLabel.topAnchor.constraint(equalTo: self.slider.bottomAnchor, constant: 10),
            maxLabel.trailingAnchor.constraint(equalTo: self.slider.trailingAnchor),
            saveButton.topAnchor.constraint(equalTo: minLabel.bottomAnchor, constant: 10),
            saveButton.trailingAnchor.constraint(equalTo: alertController!.view.trailingAnchor, constant: -20),
            zeroButton.topAnchor.constraint(equalTo: minLabel.bottomAnchor, constant: 10),
            zeroButton.leadingAnchor.constraint(equalTo: alertController!.view.leadingAnchor, constant: 20)
        ])

        // Present alert controller
        present(alertController!, animated: true, completion: nil)
    }
    
    @objc func controlTypeChanged(_ sender: UISegmentedControl) {
        let selectedIndex = sender.selectedSegmentIndex
        guard let minTextField = alertController?.textFields?[0] else { return }
        guard let maxTextField = alertController?.textFields?[1] else { return }
        guard let ticksPerMmTextField = alertController?.textFields?[2] else { return }
        switch selectedIndex {
        case 0: // Servo
            // Set text field values to 0 and 180
            minTextField.text = "0"
            maxTextField.text = "180"
            ticksPerMmTextField.text = "18"
        case 1: // Linear Actuator
            // Set text field values to 0 and 4095
            minTextField.text = "0"
            maxTextField.text = "4095"
            ticksPerMmTextField.text = "18"
        default:
            break
        }
    }
    
    @objc func saveButtonTapped() {
        // Handle Save button tap
        guard let minText = self.alertController?.textFields?[0].text,
              let maxText = self.alertController?.textFields?[1].text,
              let ticksPerMmText = self.alertController?.textFields?[2].text,
              let minValue = Float(minText),
              let maxValue = Float(maxText),
              let ticksPerMmValue = Float(ticksPerMmText) else {
            return
        }
        
        
        guard minValue <= maxValue else {
            // Show an error alert
            let errorAlert = UIAlertController(title: "Error", message: "Minimum value cannot be larger than maximum value.", preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(errorAlert, animated: true, completion: nil)
            return
        }
        // Update the min and max labels with the entered values
        self.minLabel.text = minText
        self.maxLabel.text = maxText
        
        isModalOpen = false

        self.outputMin = minValue
        self.outputMax = maxValue
        self.ticksPerMm = ticksPerMmValue
        
        self.slider.minimumValue = minValue
        self.slider.maximumValue = maxValue
        self.slider.value = (minValue + maxValue) / 2
    }

    @objc func zeroButtonTapped() {
        // Handle Zero button tap
        // Get the current value of the slider
        let sliderValue = self.slider.value
        
        // Convert the slider value to a string and assign it to the minTextField
        alertController?.textFields?.first?.text = "\(sliderValue)"
    }

    
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
        connectClippersButton.addTarget(self, action: #selector(disconnectClippers), for: .touchUpInside)
        connectClippersButton.isEnabled = true
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from " +  peripheral.name!)
        connectClippersButton.setTitle("Connect", for: .normal)
        connectClippersButton.removeTarget(self, action: #selector(disconnectClippers), for: .touchUpInside)
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
        
        drawCircle()
        
        let informationItem = UIBarButtonItem(customView: informationButton)
        
        navigationItem.rightBarButtonItem = informationItem
        
        view.addSubview(heightLabel)
        
        NSLayoutConstraint.activate([
            heightLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            heightLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
        ])
        
        
        view.addSubview(resetOrientationButton)
        
        NSLayoutConstraint.activate([
            resetOrientationButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            resetOrientationButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),

        ])
        
        view.addSubview(connectClippersButton)
        
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
        let modelMin = 0.5
        let modelMax = 0.85

        let clampedValue = clamp(inputValue, modelMin, modelMax)
        let scaledValue = scale(clampedValue, modelMin, modelMax, Double(outputMin), Double(outputMax))
        
        let height = String(format: "%.3f", scaledValue)
        
        DispatchQueue.main.async {
            self.heightLabel.text = "Height: \(height)"
        }
        if !isModalOpen {
            sendText(text: height)
        }
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

class CustomSlider: UISlider {
    private let touchAreaEdgeInsets = UIEdgeInsets(top: -15, left: -15, bottom: -15, right: -15)

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let increasedBounds = bounds.inset(by: touchAreaEdgeInsets)
        return increasedBounds.contains(point) ? self : nil
    }
}
