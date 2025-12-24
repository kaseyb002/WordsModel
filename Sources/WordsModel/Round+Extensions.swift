import Foundation

extension Round {
    public func isPlayersTurn(playerID: String) -> Bool {
        switch state {
        case .waitingForPlayer(let id):
            return playerID == id
        case .gameComplete:
            return false
        }
    }
    
    public func player(byID id: String) -> Player? {
        playerRacks.first(where: { $0.player.id == id })?.player
    }
    
    public var currentPlayer: Player? {
        switch state {
        case .waitingForPlayer(let playerID):
            return player(byID: playerID)
        case .gameComplete:
            return nil
        }
    }
    
    public func playerRack(for playerID: String) -> PlayerRack? {
        playerRacks.first(where: { $0.player.id == playerID })
    }
    
    public func tile(at position: BoardPosition) -> Tile? {
        guard position.row >= 0 && position.row < rows &&
              position.column >= 0 && position.column < columns
        else {
            return nil
        }
        
        guard let tileID = board[position.row][position.column] else {
            return nil
        }
        
        return tilesMap[tileID]
    }
    
    public var isGameComplete: Bool {
        switch state {
        case .gameComplete:
            return true
            
        case .waitingForPlayer:
            return false
        }
    }
    
    public var winner: Player? {
        switch state {
        case .gameComplete(let winner):
            return winner
            
        case .waitingForPlayer:
            return nil
        }
    }
    
    public var tilesRemainingInBag: Int {
        tileBag.count
    }
    
    private func highestScoringWord(from placements: [TilePlacement]) -> [TilePlacement]? {
        // get the highest scoring word that was created from this placement of tiles
        // return the tile placements
        
        // Get all words that will be formed from these placements
        guard let words = try? getAllWordsThatWillBeFormed(placements: placements) else {
            return nil
        }
        
        guard !words.isEmpty else {
            return nil
        }
        
        // Calculate score for each word and find the highest scoring one
        var highestScoringWordPlacements: [TilePlacement]?
        var highestScore = 0
        
        for word in words {
            guard let wordScore = try? scoreForWord(word) else {
                continue
            }
            
            if wordScore > highestScore {
                highestScore = wordScore
                highestScoringWordPlacements = word
            }
        }
        
        return highestScoringWordPlacements
    }
}

extension Round.State {
    public var isComplete: Bool {
        switch self {
        case .gameComplete:
            return true
        case .waitingForPlayer:
            return false
        }
    }
}
