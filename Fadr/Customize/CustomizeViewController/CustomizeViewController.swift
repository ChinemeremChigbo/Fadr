import UIKit
import UserNotifications

class CustomizeViewController: UIViewController {
  
  // MARK: - View Controller's Life Cycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Navigation Bar
    setupNavigationBar()

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
  
}


// MARK: - Setup UI 
extension CustomizeViewController {
  
  func setupNavigationBar() {
    title = "Customize"
  }
  
}
