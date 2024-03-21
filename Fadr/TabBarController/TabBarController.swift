import UIKit

// Describes a product object's type
typealias ProductDictionary = [String:AnyObject]


class TabBarController: UITabBarController {

  // MARK: - Properties
  
  // Tab Bar
  var currentTabIndex = 0
  
  // Image Loader
  var imageLoader: ImageDownloader?
  
  // Products
  var productCollections: [ProductCollection] = []
  
  
  
  // MARK: - View Controller's Life Cycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // TabBar's Delegate
    delegate = self
    
    // Image Loader
    imageLoader = ImageDownloader()
    
    // Load JSON Data
    loadJsonData()
    
    // Become the Children's delegate
    setupChildrenDelegates()
    
    // Setup the TabBar items title and style
    customizeTabBarItems()
    
  }

}


// MARK: - Setup UI

extension TabBarController {
  
  // Setup the TabBar items title and style
  func customizeTabBarItems() {
    
    let tabBarItems = tabBar.items
    tabBarItems?[0].title = "Collections"
    tabBarItems?[1].title = "Customize"
    tabBar.tintColor = .label
    tabBar.unselectedItemTintColor = .systemGray3
  }
  
}


// MARK: - Setup Children Delegates

/*
 Become the delegate of children's top controllers
 */
extension TabBarController {
  
  func setupChildrenDelegates() {
    setupProductOverviewVcDelegate()
  }
  
  // Child 1
  func setupProductOverviewVcDelegate() {
    
    if
      let navController = getChildNavigationController(with: 0),
      let rootController = navController.topViewController as? ProductOverviewViewController
    {
      navController.navigationBar.prefersLargeTitles = true
      rootController.productCollections = productCollections
      rootController.imageLoader = imageLoader
    }
  }
  
  
  // Get a child NavigationController
  func getChildNavigationController(with index: Int) -> UINavigationController? {
    
    if let navController = children[index] as? UINavigationController {
      return navController
    }
    return nil
  }
  
}


// MARK: - Load the Products data

extension TabBarController {
  
  // Load the data from the products.json file
  func loadJsonData() {
    let products = JsonLoader.returnProductCollectionTypeArray(
      from: "products")
    productCollections = products
  }
  
}
