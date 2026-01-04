import Foundation

extension Player {
    public static func fake(
        id: String = UUID().uuidString,
        name: String = "Player",
        imageURL: URL? = nil,
        score: Int = 0,
        color: PlayerColor = .red
    ) -> Self {
        return Player(
            id: id,
            name: name,
            imageURL: imageURL,
            score: score,
            color: color
        )
    }
}

