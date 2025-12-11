import Foundation

public struct Player: Equatable, Codable, Sendable {
    public let id: String
    public var name: String
    public var imageURL: URL?
    public var score: Int
    
    public enum CodingKeys: String, CodingKey {
        case id
        case name
        case imageURL = "imageUrl"
        case score
    }
    
    public init(
        id: String,
        name: String,
        imageURL: URL?,
        score: Int = 0
    ) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.score = score
    }
}
