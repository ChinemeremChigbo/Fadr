import UIKit
import UserNotifications

class CustomizeViewController: UIViewController {
    
    // MARK: - View Controller's Life Cycle
    let slider = UISlider()
    let valueLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    
}


// MARK: - Setup UI
extension CustomizeViewController {
    
    func setupNavigationBar() {
        title = "Customize"
    }
    func setupUI() {
        // Slider
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.value = 50 // Initial value
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        
        // Label to display slider value
        valueLabel.textAlignment = .center
        valueLabel.text = "Value: \(Int(slider.value))"
        
        // Add subviews
        view.addSubview(slider)
        view.addSubview(valueLabel)
        
        // Constraints
        slider.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            slider.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            slider.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            slider.widthAnchor.constraint(equalToConstant: 200),
            
            valueLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            valueLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func sliderValueChanged(_ sender: UISlider) {
        valueLabel.text = "Value: \(Int(sender.value))"
    }
}
