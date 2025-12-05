import Foundation

public struct WordPlacementResult: Equatable {
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
