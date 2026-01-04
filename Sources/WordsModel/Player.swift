import Foundation

public struct Player: Equatable, Codable, Sendable {
    public let id: String
    public var name: String
    public var imageURL: URL?
    public var score: Int
    public let color: PlayerColor
    
    public enum CodingKeys: String, CodingKey {
        case id
        case name
        case imageURL = "imageUrl"
        case score
        case color
    }
    
    public init(
        id: String,
        name: String,
        imageURL: URL?,
        score: Int = 0,
        color: PlayerColor
    ) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.score = score
        self.color = color
    }
    
    public func changeColor(color: PlayerColor) -> Player {
        Player(
            id: id,
            name: name,
            imageURL: imageURL,
            score: score,
            color: color
        )
    }
}
