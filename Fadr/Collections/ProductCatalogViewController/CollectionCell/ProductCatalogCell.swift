import UIKit


class ProductCatalogCell: UICollectionViewCell {
    
    
    // MARK: - Properties
    
    // View Container
    @IBOutlet weak var containerView: UIView!
    
    // Image properties
    @IBOutlet weak var productImageView: UIImageView!
    var onReuse: () -> Void = {}
    
    // Product Information
    @IBOutlet weak var productNameLabel: UILabel!
    
    // MARK: - awakeFromNib
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Add drop shadow to the cell
        addDropShadowToView()
        
        // UI Style
        setupThumbnail()
    }
    
    
    // MARK: - prepareForReuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Get the imageView ready for a new image load
        onReuse()
        productImageView.image = nil
    }
}

// MARK: - UI Style
extension ProductCatalogCell {
    
    // Add drop shadow to the cell's view
    func addDropShadowToView() {
        backgroundColor = .clear
        addDropShadow(
            opacity: 0.23,
            radius: 4,
            offset: CGSize.zero,
            lightColor: .darkGray,
            darkColor: .white
        )
    }
    
    func setupThumbnail() {
        productImageView.addCornerRadius(5)
    }
    
}
