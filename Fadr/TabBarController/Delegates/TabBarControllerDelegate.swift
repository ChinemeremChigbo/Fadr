import UIKit


// UITabBarControllerDelegate

extension TabBarController: UITabBarControllerDelegate {
  

  // MARK: - User tapped on TabBarItem
  
  func tabBarController(_ tabBarController: UITabBarController) {
    
    let selectedTabIndex = tabBarController.selectedIndex
    
    if selectedTabIndex != currentTabIndex {
      currentTabIndex = selectedTabIndex
    }
  }
}
