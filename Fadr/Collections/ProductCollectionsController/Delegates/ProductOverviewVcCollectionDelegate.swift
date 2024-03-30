import UIKit


// UICollectionViewDelegate, UICollectionViewDataSource

extension ProductOverviewViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    
    // MARK: - Section count
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    // MARK: - numberOfItemsInSection
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return productCollections.count
    }
    
    
    // MARK: - cellForItemAt
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: productCollectionCellID,
            for: indexPath) as! ProductCollectionCell
        
        // Add the name of the product type
        cell.collectionNameLabel.text = CollectionProductInfoHelper
            .getProductCollectionTypeName(from: indexPath.row)
        
        
        // Load the image of the product from imageFileName
        if let imageFileName = productCollections[indexPath.row].imageFileName,
           let image = UIImage(named: imageFileName) {
            // The UI must be accessed through the main thread
            DispatchQueue.main.async {
                cell.productImageView.image = image
            }
        }
        
        return cell
    }
    
    
    // MARK: - The cell was tapped
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        /*
         Get the list of products to pass to ProductCatalogViewController
         based on the product type the user tapped on
         */
        let index = indexPath.row
        let productList = productCollections[index].products
        userTappedProductCollection = productList
        userTappedProductCollectionName = CollectionProductInfoHelper
            .getProductCollectionTypeName(from: index)
        
        // Go to ProductCatalogViewController
        performSegue(withIdentifier: productCatalogSegue, sender: self)
    }
    
    
    // MARK: - Animate the cell being tapped
    
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        
        let cell = collectionView.cellForItem(at: indexPath)
        ObjectCollectionHelper.highlightCellOnTap(for: cell!)
        return true
    }
    
}
