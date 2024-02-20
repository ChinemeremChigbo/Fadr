import UIKit
import CoreMotion
import simd

class InformationViewController: UIViewController, CMHeadphoneMotionManagerDelegate {
    
    
    lazy var textView: UITextView = {
        let view = UITextView()
        view.frame = CGRect(x: self.view.bounds.minX + (self.view.bounds.width / 10),
                            y: self.view.bounds.minY + (self.view.bounds.height / 10),
                            width: self.view.bounds.width, height: self.view.bounds.height)
        view.text = "Looking for headphones and phone"
        view.font = view.font?.withSize(14)
        view.isEditable = false
        return view
    }()
    
    let headphone = CMHeadphoneMotionManager()
    let phone = CMMotionManager()
    var headphoneData: CMDeviceMotion?
    var phoneData: CMDeviceMotion?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Information View"
        view.backgroundColor = .systemBackground
        view.addSubview(textView)
        
        
        guard headphone.isDeviceMotionAvailable else {
            AlertView.alert(self, "Sorry", "Your headphones are not supported.")
            textView.text = "Sorry, Your headphones are not supported."
            return
        }
        
        guard phone.isDeviceMotionAvailable else {
            AlertView.alert(self, "Sorry", "Your phone is not supported.")
            textView.text = "Sorry, Your phone is not supported."
            return
        }
        
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 2
        
        headphone.startDeviceMotionUpdates(to: queue) { [weak self] motion, error in
            guard let motion = motion, error == nil else { return }
            self?.headphoneData = motion
            self?.updateData()
        }
        
        phone.startDeviceMotionUpdates(to: queue) { [weak self] motion, error in
            guard let motion = motion, error == nil else { return }
            self?.phoneData = motion
            self?.updateData()
        }
        
    }
    override func viewWillAppear(_ animated: Bool) {
        self.viewDidLoad()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        headphone.stopDeviceMotionUpdates()
        phone.stopDeviceMotionUpdates()
        
    }
    
    func updateData() {
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
        
        
        DispatchQueue.main.async {
            self.textView.text = """
                            Headphone Data:
                            Quaternion:
                                x: \(headphoneData.attitude.quaternion.x)
                                y: \(headphoneData.attitude.quaternion.y)
                                z: \(headphoneData.attitude.quaternion.z)
                                w: \(headphoneData.attitude.quaternion.w)
                            Attitude:
                                pitch: \(headphoneData.attitude.pitch)
                                roll: \(headphoneData.attitude.roll)
                                yaw: \(headphoneData.attitude.yaw)
                            
                            Phone Data:
                            Quaternion:
                                x: \(phoneData.attitude.quaternion.x)
                                y: \(phoneData.attitude.quaternion.y)
                                z: \(phoneData.attitude.quaternion.z)
                                w: \(phoneData.attitude.quaternion.w)
                            Attitude:
                                pitch: \(phoneData.attitude.pitch)
                                roll: \(phoneData.attitude.roll)
                                yaw: \(phoneData.attitude.yaw)
                            
                            Relative Data:
                            Quaternion:
                                x: \(relative_quaternion.vector.x)
                                y: \(relative_quaternion.vector.y)
                                z: \(relative_quaternion.vector.z)
                                w: \(relative_quaternion.vector.w)
                            """
        }
        
    }
}
