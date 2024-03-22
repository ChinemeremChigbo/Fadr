// MARK: - Product Array

struct ProductInformation: Codable {
  let products: [Product]
}


// MARK: - Product Object

struct Product: Codable {
  let id: String
  let name: String
  let type: String
  let imageFileName: String?
  let modelFileName: String?
}

// MARK: - Product Collection 

struct ProductCollection {
    let type: String
    let products: [Product]
    let imageFileName: String?
}
