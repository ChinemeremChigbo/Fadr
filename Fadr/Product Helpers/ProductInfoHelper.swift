import Foundation


struct ProductInfoHelper {

  
  
  // MARK: - Product ImageURL
  
  // Can create the imageURL to load the image
  static func canCreateImageUrl(from imageUrl: String?) -> URL? {
    if
      let productImageUrlString = imageUrl,
      let productImageURL = URL(string: productImageUrlString)
    {
      return productImageURL
    }
    
    return nil
  }
  
}
