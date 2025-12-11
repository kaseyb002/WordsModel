import Foundation

public struct WordPlacementResult: Equatable, Sendable {
    public let tilePlacements: [TilePlacement]
    public let points: Int
    
    public init(
        tilePlacements: [TilePlacement],
        points: Int
    ) {
        self.tilePlacements = tilePlacements
        self.points = points
    }
}
