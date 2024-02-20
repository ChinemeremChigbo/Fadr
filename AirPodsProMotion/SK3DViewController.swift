import UIKit
import SceneKit
import CoreMotion

class SK3DViewController: UIViewController, CMHeadphoneMotionManagerDelegate {
    
    let APP = CMHeadphoneMotionManager()
    var cubeNode: SCNNode!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .systemBackground
        self.title = "Simple 3D View"
        
        APP.delegate = self

        SceneSetUp()
        
        guard APP.isDeviceMotionAvailable else {
            AlertView.alert(self, "Sorry", "Your device is not supported.")
            return
        }
        APP.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: {[weak self] motion, error  in
            guard let motion = motion, error == nil else { return }
            self?.NodeRotate(motion)
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.viewDidLoad()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        APP.stopDeviceMotionUpdates()
    }
    
    
    func NodeRotate(_ motion: CMDeviceMotion) {
        let data = motion.attitude

        cubeNode.eulerAngles = SCNVector3(-data.pitch, -data.yaw, -data.roll)
    }
}


// SceneKit
extension SK3DViewController {
    
    func SceneSetUp() {
        let scnView = SCNView(frame: self.view.frame)
        scnView.backgroundColor = UIColor.black
        scnView.allowsCameraControl = false
        scnView.showsStatistics = true
        view.addSubview(scnView)

        // Set SCNScene to SCNView
        let scene = SCNScene()
        scnView.scene = scene

        // Adding a camera to a scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        scene.rootNode.addChildNode(cameraNode)

        // Adding an omnidirectional light source to the scene
        let omniLight = SCNLight()
        omniLight.type = .omni
        let omniLightNode = SCNNode()
        omniLightNode.light = omniLight
        omniLightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(omniLightNode)

        // Adding a light source to your scene that illuminates from all directions.
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor.darkGray
        let ambientLightNode = SCNNode()
        ambientLightNode.light = ambientLight
        scene.rootNode.addChildNode(ambientLightNode)

    
        // Adding a cube(face) to a scene
        let cube:SCNGeometry = SCNBox(width: 3, height: 3, length: 3, chamferRadius: 0.5)
        
        cubeNode = SCNNode(geometry: cube)
        cubeNode.position = SCNVector3(x: 0, y: 0, z: 0)
        scene.rootNode.addChildNode(cubeNode)
    }
}
