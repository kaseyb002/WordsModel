import Foundation

extension PlayerRack {
    public static func fake(
        player: Player = .fake(),
        tiles: [TileID] = []
    ) -> Self {
        return PlayerRack(
            player: player,
            tiles: tiles
        )
    }
}

