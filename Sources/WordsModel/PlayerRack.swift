import Foundation

public struct PlayerRack: Equatable, Codable {
    public var player: Player
    public var tiles: [TileID]
    
    public init(
        player: Player,
        tiles: [TileID]
    ) {
        self.player = player
        self.tiles = tiles
    }
}
