import UIKit
import CoreBluetooth
import UserNotifications

class CustomizeViewController: UIViewController, CBCentralManagerDelegate {
    
    // MARK: - View Controller's Life Cycle
    let slider = UISlider()
    let valueLabel = UILabel()
    
    var bluetooth = CBCentralManager()
    let serviceUUID = CBUUID(string: "ab0828b1-198e-4351-b779-901fa0e0371e")
    let peripheralName = "BLETest"
    var myPeripheral:CBPeripheral?
    var myCharacteristic:CBCharacteristic?
    
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
        connectClippersButton.setTitle("Disconnect Clippers", for: .normal)
        connectClippersButton.removeTarget(self, action: #selector(connectClippers), for: .touchUpInside)
        connectClippersButton.addTarget(self, action: #selector(disconnectFromClippers), for: .touchUpInside)
        connectClippersButton.isEnabled = true
    }
    
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from " +  peripheral.name!)
        connectClippersButton.setTitle("Connect Clippers", for: .normal)
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bluetooth.delegate = self
        
        
        // Navigation Bar
        setupNavigationBar()
        
        // Setup UI
        setupUI()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    // MARK: - View transition
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        /*
         Allow the large title in the navigationBar to go back
         to normal size on the view's transition to portrait orientation
         */
        coordinator.animate { (_) in
            self.navigationController?.navigationBar.sizeToFit()
        }
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

// MARK: - Setup UI
extension CustomizeViewController: CBPeripheralDelegate {
    
    func setupNavigationBar() {
        title = "Customize"
    }
    func setupUI() {
        // Slider
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.value = (slider.minimumValue + slider.maximumValue) / 2
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        
        // Label to display slider value
        valueLabel.textAlignment = .center
        valueLabel.text = "Value: (Move slider to set)"
        
        // Rotate slider
        slider.transform = CGAffineTransform(rotationAngle: -.pi / 2)
        connectClippersButton.setTitle("Connect Clippers", for: .normal)
        connectClippersButton.addTarget(self, action: #selector(connectClippers), for: .touchUpInside)
        
        // Add subviews
        view.addSubview(slider)
        view.addSubview(valueLabel)
        view.addSubview(connectClippersButton)
        
        // Constraints
        slider.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        connectClippersButton.translatesAutoresizingMaskIntoConstraints = false
        
        
        NSLayoutConstraint.activate([
            slider.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            slider.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 50),
            slider.widthAnchor.constraint(equalToConstant: 300),
            
            valueLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            valueLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            connectClippersButton.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 20),
            connectClippersButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func sliderValueChanged(_ sender: UISlider) {
        let inputValue = sender.value
        let inputMin = sender.minimumValue
        let inputMax = sender.maximumValue
        let outputMin: Float = 0
        let outputMax: Float = 4095
        
        let clampedValue = clamp(inputValue, inputMin, inputMax)
        let scaledValue = scale(clampedValue, inputMin, inputMax, outputMin, outputMax)
        print("\(Int(scaledValue))")
        
        valueLabel.text = "Value: \(Int(scaledValue))"
        sendText(text: "\(Int(scaledValue))")
    }
    
    private func clamp(_ value: Float, _ min: Float, _ max: Float) -> Float {
        return Swift.min(Swift.max(value, min), max)
    }
    
    private func scale(_ value: Float, _ inputMin: Float, _ inputMax: Float, _ outputMin: Float, _ outputMax: Float) -> Float {
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
