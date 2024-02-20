import UIKit
import CoreMotion

class InformationViewController: UIViewController, CMHeadphoneMotionManagerDelegate {
    
    lazy var textViewHeadphone: UITextView = {
        let view = UITextView()
        view.frame = CGRect(x: self.view.bounds.minX + (self.view.bounds.width / 10),
                            y: self.view.bounds.minY + (self.view.bounds.height / 10),
                            width: self.view.bounds.width, height: self.view.bounds.height / 2)
        view.text = "Looking for headphones"
        view.font = view.font?.withSize(14)
        view.isEditable = false
        return view
    }()
    
    lazy var textViewPhone: UITextView = {
        let view = UITextView()
        view.frame = CGRect(x: self.view.bounds.minX + (self.view.bounds.width / 10),
                            y: self.view.bounds.height / 2  + (self.view.bounds.height / 10),
                            width: self.view.bounds.width, height: self.view.bounds.height / 2)
        view.text = "Looking for phone"
        view.font = view.font?.withSize(14)
        view.isEditable = false
        return view
    }()
    
    
    let headphone = CMHeadphoneMotionManager()
    let phone = CMMotionManager()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Information View"
        view.backgroundColor = .systemBackground
        view.addSubview(textViewHeadphone)
        view.addSubview(textViewPhone)
        
        
        
        //        headphone.delegate = self
        
        guard headphone.isDeviceMotionAvailable else {
            AlertView.alert(self, "Sorry", "Your headphones are not supported.")
            textViewHeadphone.text = "Sorry, Your headphones are not supported."
            return
        }
        
        guard phone.isDeviceMotionAvailable else {
            AlertView.alert(self, "Sorry", "Your phone is not supported.")
            textViewPhone.text = "Sorry, Your phone is not supported."
            return
        }
        
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 2
        
        headphone.startDeviceMotionUpdates(to: queue) { [weak self] motion, error in
            guard let motion = motion, error == nil else { return }
            self?.printData(motion, for: "Headphone", textview: self?.textViewHeadphone ?? UITextView())
        }
        
        phone.startDeviceMotionUpdates(to: queue) { [weak self] motion, error in
            guard let motion = motion, error == nil else { return }
            self?.printData(motion, for: "Phone", textview: self?.textViewPhone ?? UITextView())
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.viewDidLoad()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        headphone.stopDeviceMotionUpdates()
    }
    
    
    func printData(_ data: CMDeviceMotion, for source: String, textview: UITextView) {
        DispatchQueue.main.async {
            print("\(source) data: \(data)")
            textview.text = """
                \(source) Data:
                Quaternion:
                    x: \(data.attitude.quaternion.x)
                    y: \(data.attitude.quaternion.y)
                    z: \(data.attitude.quaternion.z)
                    w: \(data.attitude.quaternion.w)
                Attitude:
                    pitch: \(data.attitude.pitch)
                    roll: \(data.attitude.roll)
                    yaw: \(data.attitude.yaw)
                """
        }
        
    }
}
