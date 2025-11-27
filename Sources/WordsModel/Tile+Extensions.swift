import Foundation

extension [TileID: Tile] {
    public func findTiles(byIDs tileIDs: [TileID]) -> [Tile] {
        tileIDs.compactMap { self[$0] }
    }
}
