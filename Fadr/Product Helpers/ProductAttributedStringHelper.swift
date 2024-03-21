import Foundation


struct ProductAttributedStringHelper {
  
  
  // MARK: - Product Name
  
  static func getAttributedName(from name: String, withSize fontSize: CGFloat) -> NSAttributedString {
    return name.toStyleString(with: fontSize, and: .bold)
  }
  
}
