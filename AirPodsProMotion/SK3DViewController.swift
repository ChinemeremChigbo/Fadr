import UIKit
import SceneKit
import CoreMotion

class SK3DViewController: UIViewController, CMHeadphoneMotionManagerDelegate {
    
    var origin_quaternion = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)
    var first_quaternion = true
    let headphone = CMHeadphoneMotionManager()
    let phone = CMMotionManager()
    var headphoneData: CMDeviceMotion?
    var phoneData: CMDeviceMotion?
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Simple 3D View"
        self.view.backgroundColor = .systemBackground
        headphone.delegate = self
        
        SceneSetUp()
        
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
        
        let button = UIButton(type: .system)
        button.setTitle("Stop and Reset", for: .normal)
        button.addTarget(self, action: #selector(stopAndReset), for: .touchUpInside)
        view.addSubview(button)
        
        
        
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(colorLabel)
        NSLayoutConstraint.activate([
            colorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            colorLabel.bottomAnchor.constraint(equalTo: view.topAnchor, constant: 100),
            
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50)
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
                                              iy: headphoneData.attitude.quaternion.y,
                                              iz: headphoneData.attitude.quaternion.z,
                                              r: headphoneData.attitude.quaternion.w)
        
        let phone_quaternion = simd_quatd(ix: phoneData.attitude.quaternion.x,
                                          iy: phoneData.attitude.quaternion.y,
                                          iz: phoneData.attitude.quaternion.z,
                                          r: phoneData.attitude.quaternion.w)
        
        let relative_quaternion = headphone_quaternion.inverse * phone_quaternion;
        let relative_quaternion_float = simd_quatf(ix: Float(relative_quaternion.vector.x),
                                                   iy: Float(relative_quaternion.vector.y),
                                                   iz: Float(relative_quaternion.vector.z),
                                                   r: Float(relative_quaternion.vector.w))
        
        hairHeightNode?.simdOrientation = relative_quaternion_float.inverse * origin_quaternion
        
    }
    @objc func stopAndReset() {
        
        guard let currentOrientation = hairHeightNode?.simdOrientation else {
            return
        }
        
        origin_quaternion = currentOrientation
    }
}


extension SK3DViewController {
    
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
        
        DispatchQueue.main.async {
            self.colorLabel.text = "Height: \(Double(round(1000 * (1 - red) ) / 1000))"
        }
    }
    
}
