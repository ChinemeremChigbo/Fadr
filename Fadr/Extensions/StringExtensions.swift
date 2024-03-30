import UIKit


extension String {
    
    // MARK: - Add Style to any String
    
    func toStyleString(with fontSize: CGFloat, and fontWeight: UIFont.Weight) -> NSAttributedString {
        
        let attributedString = NSMutableAttributedString(string: self)
        
        let attributedStringKey = [
            NSAttributedString.Key.font: UIFont
                .systemFont(ofSize: fontSize, weight: fontWeight)
        ]
        
        attributedString.setAttributes(
            attributedStringKey,
            range: NSRange(location: 0, length: self.count))
        
        return attributedString
    }
    
    // MARK: - Capitalize first letter
    
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
    
}
