import Foundation

public struct Round: Equatable, Codable {
    // MARK: - Initialized Properties
    public let id: String
    public let started: Date
    
    // MARK: - Game Configuration
    public let rows: Int
    public let columns: Int
    
    // MARK: - Round Progression
    public internal(set) var state: State
    public internal(set) var tilesMap: [TileID: Tile]
    public internal(set) var tileBag: [TileID]
    public internal(set) var playerRacks: [PlayerRack]
    public internal(set) var board: [[TileID?]]
    public internal(set) var boardSquares: [[BoardSquare]]
    public internal(set) var blankTileAssignments: [TileID: Tile.Letter] = [:]
    
    // MARK: - Results
    public internal(set) var log: [Action] = []
    public internal(set) var ended: Date?
    public internal(set) var consecutivePasses: Int = 0
    
    public enum State: Equatable, Codable {
        case waitingForPlayer(id: String)
        case gameComplete(winner: Player)
        
        public var logValue: String {
            switch self {
            case .waitingForPlayer(let playerID):
                "Waiting for player \(playerID) to play"

            case .gameComplete(let winner):
                "\(winner.name) won the game with \(winner.score) points."
            }
        }
    }
    
    public struct Action: Equatable, Codable {
        public let playerId: String
        public let action: ActionType
        public let timestamp: Date
        
        public enum ActionType: Equatable, Codable {
            case placeWord(placements: [TilePlacement], score: Int)
            case pass
            case exchange(tileIDs: [TileID])
        }
        
        public init(
            playerId: String,
            action: ActionType,
            timestamp: Date
        ) {
            self.playerId = playerId
            self.action = action
            self.timestamp = timestamp
        }
    }
}
