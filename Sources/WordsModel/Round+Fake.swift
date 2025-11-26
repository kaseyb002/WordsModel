import Foundation

extension Round {
    public static func fake(
        id: String = UUID().uuidString,
        started: Date = .now,
        rows: Int = 15,
        columns: Int = 15,
        cookedTiles: [Tile]? = nil,
        players: [Player] = [
            .fake(name: "Player 1"),
            .fake(name: "Player 2")
        ]
    ) throws -> Round {
        return try Round(
            id: id,
            started: started,
            rows: rows,
            columns: columns,
            cookedTiles: cookedTiles,
            players: players
        )
    }
}

