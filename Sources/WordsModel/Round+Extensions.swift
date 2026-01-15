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
    
    public func playerColor(forTileAt position: BoardPosition) -> PlayerColor? {
        // Look through log in reverse order to find the most recent placement at this position
        for action in log.reversed() {
            if case .placeWord(let placements, _, _) = action.action {
                if placements.contains(where: { $0.position == position }) {
                    // Found the player who placed a tile at this position
                    return player(byID: action.playerId)?.color
                }
            }
        }
        return nil
    }
    
    public func highestScoringWord(from placements: [TilePlacement]) -> [TilePlacement]? {
        // get the highest scoring word that was created from this placement of tiles
        // return the tile placements
        
        // Get all words that will be formed from these placements
        guard let words = try? getAllWordsThatWillBeFormed(placements: placements) else {
            return nil
        }
        
        guard !words.isEmpty else {
            return nil
        }
        
        // Track which positions have newly placed tiles (premium squares only apply to these)
        let newlyPlacedPositions = Set(placements.map { $0.position })
        
        // Calculate score for each word and find the highest scoring one
        var highestScoringWordPlacements: [TilePlacement]?
        var highestScore = 0
        
        for word in words {
            guard let wordScore = try? scoreForWord(word, newlyPlacedPositions: newlyPlacedPositions) else {
                continue
            }
            
            if wordScore > highestScore {
                highestScore = wordScore
                highestScoringWordPlacements = word
            }
        }
        
        return highestScoringWordPlacements
    }
    
    /// Returns all valid words formed at the given board position
    /// - Parameter boardPosition: The position to check for words
    /// - Returns: An array of word strings (uppercase) formed at this position, empty if no tile exists or no words are formed
    public func wordsFormed(in boardPosition: BoardPosition) -> [String] {
        // Check if there's a tile at this position
        guard tile(at: boardPosition) != nil else {
            return []
        }
        
        var words: [String] = []
        
        // Build horizontal word (left to right)
        if let horizontalWord = buildWordAtPosition(
            row: boardPosition.row,
            column: boardPosition.column,
            isHorizontal: true
        ), horizontalWord.count > 1 {
            if let wordString = try? wordString(from: horizontalWord) {
                words.append(wordString)
            }
        }
        
        // Build vertical word (top to bottom)
        if let verticalWord = buildWordAtPosition(
            row: boardPosition.row,
            column: boardPosition.column,
            isHorizontal: false
        ), verticalWord.count > 1 {
            if let wordString = try? wordString(from: verticalWord) {
                words.append(wordString)
            }
        }
        
        return words
    }
    
    /// Builds a word at the given position by searching in one direction
    public func buildWordAtPosition(
        row: Int,
        column: Int,
        isHorizontal: Bool
    ) -> [TilePlacement]? {
        var word: [TilePlacement] = []
        
        if isHorizontal {
            // Search left until we hit an empty space
            var leftmostCol = column
            while leftmostCol > 0 {
                let pos = BoardPosition(row: row, column: leftmostCol - 1)
                if tile(at: pos) != nil {
                    leftmostCol -= 1
                } else {
                    break
                }
            }
            
            // Build word from left to right until we hit an empty space
            var currentCol = leftmostCol
            while currentCol < columns {
                let pos = BoardPosition(row: row, column: currentCol)
                guard let tileID = board[pos.row][pos.column] else {
                    break
                }
                
                let placement = TilePlacement(
                    tileID: tileID,
                    position: pos,
                    blankLetterUsedAs: blankTileAssignments[tileID]
                )
                word.append(placement)
                currentCol += 1
            }
        } else {
            // Search up until we hit an empty space
            var topmostRow = row
            while topmostRow > 0 {
                let pos = BoardPosition(row: topmostRow - 1, column: column)
                if tile(at: pos) != nil {
                    topmostRow -= 1
                } else {
                    break
                }
            }
            
            // Build word from top to bottom until we hit an empty space
            var currentRow = topmostRow
            while currentRow < rows {
                let pos = BoardPosition(row: currentRow, column: column)
                guard let tileID = board[pos.row][pos.column] else {
                    break
                }
                
                let placement = TilePlacement(
                    tileID: tileID,
                    position: pos,
                    blankLetterUsedAs: blankTileAssignments[tileID]
                )
                word.append(placement)
                currentRow += 1
            }
        }
        
        return word.isEmpty ? nil : word
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
