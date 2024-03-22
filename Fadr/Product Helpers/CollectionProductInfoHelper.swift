import Foundation


// MARK: - Product Collection Types enum

// Product Collection Types
enum CollectionType: String, CaseIterable {
    case hair
    case beard
    
    // Returns the title to use
    var productTypeTitle: String {
        switch self {
        case .hair:
            return "Hair"
        case .beard:
            return "Beard"
        }
    }
    
    // Returns the image file name to use
    var productTypeImageFileName: String {
        switch self {
        case .hair:
            return "hair_collection.png"
        case .beard:
            return "beard_collection.png"
        }
    }
}


struct CollectionProductInfoHelper {
    
    
    // MARK: - Get Product Collection type
    
    // Get the product collection type name
    static  func getProductCollectionTypeName(from index: Int) -> String {
        
        let collectionTypeCases = CollectionType.allCases
        
        if index <= collectionTypeCases.count-1 {
            let collectionName = collectionTypeCases[index].productTypeTitle
            return collectionName
        }
        
        return ""
    }
}
