import UIKit
import Foundation


class ProductCatalogViewController: UIViewController {
    
    // MARK: - Properties
    
    // ProductPageViewController
    let productPageViewControllerSegue = "ProductPageViewControllerSegue"
    var userTappedProductObj: Product?
    
    // Title
    var collectionName = ""
    var backButtonTitle = ""
    
    // Product Catalog
    var productList: [Product] = []
    
    // Products Collection View
    @IBOutlet weak var productCatalogCollectionView: UICollectionView!
    var productCellID = "ProductCatalogCell"
    
    
    // MARK: - View Controller's Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Navigation Bar
        setupNavigationBar()
        
        // Setup the Product Catalog Collection View
        ObjectCollectionHelper.setupCollectionView(
            productCellID,
            for: productCatalogCollectionView, in: self)
        
    }
    
    
    // MARK: - ViewWillTransition
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        /*
         Reload the Products CollectionView to update
         its layout
         */
        productCatalogCollectionView.reloadData()
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //Pass data for a product to ProductPageViewController
        if segue.identifier == productPageViewControllerSegue {
            
            let viewController = segue.destination as! ProductPageViewController
            viewController.productObject = userTappedProductObj
        }
    }
    
}

// MARK: - Setup UI

extension ProductCatalogViewController {
    
    func setupNavigationBar() {
        
        title = collectionName
        navigationController?.navigationBar.topItem?
            .backButtonTitle = backButtonTitle
    }
}

// MARK: - Observers

extension ProductCatalogViewController {
    
}
