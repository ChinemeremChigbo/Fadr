import Foundation


// JSON Loading Object

struct JsonLoader {
    
    
    // MARK: - Load JSON Data
    
    static func decodingJsonData(from fileName: String) -> ProductInformation?  {
        
        var data: Data
        
        // Find the JSON file
        if let path = Bundle.main.url(forResource: fileName, withExtension: "json") {
            
            do {
                data = try Data(contentsOf: path)
            }
            catch {
                print("ERROR loading JSON data: \(fileName), with error: \(error)")
                return nil
            }
            
            do {
                
                /*
                 Decode the JSON file extracted data into
                 a ProductInformation object
                 */
                let decoder = JSONDecoder()
                let information = try decoder
                    .decode(ProductInformation.self, from: data)
                return information
                
            }
            catch let error {
                print("ERROR: \(error)")
                return nil
            }
        }
        return nil
    }
    
    
    // MARK: - Return Product Collections
    
    // Create a collection of products for every product type
    static func returnProductCollectionTypeArray(from fileName: String) -> [ProductCollection] {
        
        if let infoArray = decodingJsonData(from: fileName) {
            
            let array = infoArray.products
            
            // Loop through the enum CollectionType
            let collectionTypes = CollectionType.allCases
            var productCollections: [ProductCollection] = []
            
            for type in collectionTypes {
                
                let typeRawValue = type.rawValue
                
                // Only get the products that match the product type
                let newArr = array.filter {
                    $0.type == typeRawValue
                }
                let imageUrl = (typeRawValue == "hair") ? "https://cdn.discordapp.com/attachments/1174549760322043968/1218244645721477193/Hair.png?ex=6606f5bd&is=65f480bd&hm=1608823c9e26008d3f2952ea70b93717d2b6940318e0a8d41f16c784288e641a&" : "https://cdn.discordapp.com/attachments/1174549760322043968/1218244645377540096/Beard.png?ex=6606f5bd&is=65f480bd&hm=7c40bab1ba284bb20eb531f2cbae556f1488ac7c85c4747eacefd46dc60be0f6&"
                
                let collection = ProductCollection(
                    type: typeRawValue, products: newArr, imageUrl: imageUrl)
                
                productCollections.append(collection)
            }
            
            return productCollections
        }
        
        return []
    }
}
