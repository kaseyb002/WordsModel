import Foundation

extension Round {
    public mutating func placeWord(form: PlaceWordForm) throws {
        guard case .waitingForPlayer(let currentPlayerID) = state else {
            throw WordsModelError.notWaitingForPlayerToAct
        }
        
        guard let currentPlayerIndex = playerRacks.firstIndex(where: { $0.player.id == currentPlayerID }) else {
            throw WordsModelError.playerNotFound
        }
        
        // Validate placements
        try validatePlacements(form.placements, currentPlayerIndex: currentPlayerIndex)
        
        // Check if this is the first word (board is empty)
        let isFirstWord = board.allSatisfy { $0.allSatisfy { $0 == nil } }
        if isFirstWord {
            // First word must use center square
            let centerPosition = BoardPosition(row: 7, column: 7)
            guard form.placements.contains(where: { $0.position == centerPosition }) else {
                throw WordsModelError.firstWordMustUseCenterSquare
            }
        } else {
            // Word must connect to existing tiles
            guard wordConnectsToExistingTiles(placements: form.placements) else {
                throw WordsModelError.wordDoesNotConnectToExistingTiles
            }
        }
        
        // Place tiles on board
        var blankAssignments: [TileID: Tile.Letter] = [:]
        for placement in form.placements {
            board[placement.position.row][placement.position.column] = placement.tileID
            
            // Handle blank tiles
            if let letter = placement.letter,
               let tile = tilesMap[placement.tileID],
               tile.letter == .blank {
                blankTileAssignments[placement.tileID] = letter
                blankAssignments[placement.tileID] = letter
            }
            
            // Remove tile from player's rack
            guard let tileIndex = playerRacks[currentPlayerIndex].tiles.firstIndex(of: placement.tileID) else {
                throw WordsModelError.tileDoesNotExistInPlayersRack
            }
            playerRacks[currentPlayerIndex].tiles.remove(at: tileIndex)
        }
        
        // Calculate score
        let score = try calculateScore(placements: form.placements, isFirstWord: isFirstWord)
        playerRacks[currentPlayerIndex].player.score += score
        
        // Draw new tiles
        try drawTiles(for: currentPlayerIndex, count: form.placements.count)
        
        // Reset consecutive passes
        consecutivePasses = 0
        
        // Log action
        log.append(.init(
            playerId: currentPlayerID,
            action: .placeWord(placements: form.placements, score: score),
            timestamp: .now
        ))
        
        // Check for game end conditions
        checkGameEnd()
        
        // Advance to next player
        advanceToNextPlayer()
    }
    
    public mutating func pass() throws {
        guard case .waitingForPlayer(let currentPlayerID) = state else {
            throw WordsModelError.notWaitingForPlayerToAct
        }
        
        // Check if this is the first turn
        let isFirstWord = board.allSatisfy { $0.allSatisfy { $0 == nil } }
        if isFirstWord {
            throw WordsModelError.cannotPassOnFirstTurn
        }
        
        consecutivePasses += 1
        
        // Log action
        log.append(.init(
            playerId: currentPlayerID,
            action: .pass,
            timestamp: .now
        ))
        
        // Check for game end (all players passed consecutively)
        if consecutivePasses >= playerRacks.count {
            endGame()
            return
        }
        
        // Advance to next player
        advanceToNextPlayer()
    }
    
    public mutating func exchange(tileIDs: [TileID]) throws {
        guard case .waitingForPlayer(let currentPlayerID) = state else {
            throw WordsModelError.notWaitingForPlayerToAct
        }
        
        guard let currentPlayerIndex = playerRacks.firstIndex(where: { $0.player.id == currentPlayerID }) else {
            throw WordsModelError.playerNotFound
        }
        
        // Check if player has all tiles
        for tileID in tileIDs {
            guard playerRacks[currentPlayerIndex].tiles.contains(tileID) else {
                throw WordsModelError.tileDoesNotExistInPlayersRack
            }
        }
        
        // Check if there are enough tiles in bag
        guard tileBag.count >= tileIDs.count else {
            throw WordsModelError.insufficientTilesToExchange
        }
        
        // Return tiles to bag
        for tileID in tileIDs {
            if let index = playerRacks[currentPlayerIndex].tiles.firstIndex(of: tileID) {
                playerRacks[currentPlayerIndex].tiles.remove(at: index)
                tileBag.append(tileID)
            }
        }
        
        // Shuffle bag
        tileBag.shuffle()
        
        // Draw new tiles
        try drawTiles(for: currentPlayerIndex, count: tileIDs.count)
        
        // Reset consecutive passes
        consecutivePasses = 0
        
        // Log action
        log.append(.init(
            playerId: currentPlayerID,
            action: .exchange(tileIDs: tileIDs),
            timestamp: .now
        ))
        
        // Advance to next player
        advanceToNextPlayer()
    }
    
    // MARK: - Private Helper Methods
    
    private func validatePlacements(_ placements: [WordPlacement], currentPlayerIndex: Int) throws {
        guard !placements.isEmpty else {
            throw WordsModelError.invalidWordPlacement
        }
        
        // Check all tiles are in player's rack
        let playerTileIDs = Set(playerRacks[currentPlayerIndex].tiles)
        for placement in placements {
            guard playerTileIDs.contains(placement.tileID) else {
                throw WordsModelError.tileDoesNotExistInPlayersRack
            }
            
            // Validate blank tile letter assignment
            guard let tile = tilesMap[placement.tileID] else {
                throw WordsModelError.tileDoesNotExistInPlayersRack
            }
            
            if tile.letter == .blank {
                // Blank tiles MUST have a letter specified
                guard let assignedLetter = placement.letter, assignedLetter != .blank else {
                    throw WordsModelError.blankTileRequiresLetter
                }
            } else {
                // Non-blank tiles should NOT have a letter specified
                if placement.letter != nil {
                    throw WordsModelError.nonBlankTileCannotHaveLetter
                }
            }
            
            // Validate position
            guard placement.position.row >= 0 && placement.position.row < rows &&
                  placement.position.column >= 0 && placement.position.column < columns else {
                throw WordsModelError.invalidPosition
            }
            
            // Check position is not already occupied
            guard board[placement.position.row][placement.position.column] == nil else {
                throw WordsModelError.positionAlreadyOccupied
            }
        }
        
        // Validate word formation (all tiles must be in a line)
        try validateWordFormation(placements: placements)
    }
    
    private func validateWordFormation(placements: [WordPlacement]) throws {
        guard placements.count > 1 else { return }
        
        // Check if all placements are in a straight line (horizontal or vertical)
        let sortedByRow = placements.sorted { $0.position.row < $1.position.row || ($0.position.row == $1.position.row && $0.position.column < $1.position.column) }
        let sortedByCol = placements.sorted { $0.position.column < $1.position.column || ($0.position.column == $1.position.column && $0.position.row < $1.position.row) }
        
        // Check if horizontal
        let isHorizontal = sortedByRow.allSatisfy { $0.position.row == sortedByRow.first?.position.row }
        let isVertical = sortedByCol.allSatisfy { $0.position.column == sortedByCol.first?.position.column }
        
        guard isHorizontal || isVertical else {
            throw WordsModelError.invalidWordFormation
        }
        
        // Check if consecutive
        if isHorizontal {
            let columns = sortedByRow.map { $0.position.column }.sorted()
            for i in 1..<columns.count {
                guard columns[i] == columns[i-1] + 1 else {
                    throw WordsModelError.invalidWordFormation
                }
            }
        } else {
            let rows = sortedByCol.map { $0.position.row }.sorted()
            for i in 1..<rows.count {
                guard rows[i] == rows[i-1] + 1 else {
                    throw WordsModelError.invalidWordFormation
                }
            }
        }
    }
    
    private func wordConnectsToExistingTiles(placements: [WordPlacement]) -> Bool {
        for placement in placements {
            let row = placement.position.row
            let col = placement.position.column
            
            // Check adjacent positions
            let adjacentPositions = [
                (row - 1, col), (row + 1, col),
                (row, col - 1), (row, col + 1)
            ]
            
            for (adjRow, adjCol) in adjacentPositions {
                if adjRow >= 0 && adjRow < rows && adjCol >= 0 && adjCol < columns {
                    if board[adjRow][adjCol] != nil {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    private func calculateScore(placements: [WordPlacement], isFirstWord: Bool) throws -> Int {
        var totalScore = 0
        
        // Get all words formed (main word + any perpendicular words)
        let words = try getAllWordsFormed(placements: placements)
        
        for word in words {
            var wordScore = 0
            var wordMultiplierForThisWord = 1
            
            for placement in word {
                guard let tile = tilesMap[placement.tileID] else {
                    throw WordsModelError.tileDoesNotExistInPlayersRack
                }
                
                let square = boardSquares[placement.position.row][placement.position.column]
                let multipliers = square.multiplier
                
                // Determine letter value (use assigned letter for blanks)
                let letterValue: Int
                if tile.letter == .blank, let assignedLetter = placement.letter {
                    letterValue = assignedLetter.standardPointValue
                } else {
                    letterValue = tile.pointValue
                }
                
                let letterScore = letterValue * multipliers.letter
                wordScore += letterScore
                wordMultiplierForThisWord *= multipliers.word
            }
            
            totalScore += wordScore * wordMultiplierForThisWord
        }
        
        // Bonus for using all 7 tiles
        if placements.count == 7 {
            totalScore += 50
        }
        
        return totalScore
    }
    
    private func getAllWordsFormed(placements: [WordPlacement]) throws -> [[WordPlacement]] {
        var words: [[WordPlacement]] = []
        
        // Main word (the placements themselves)
        words.append(placements)
        
        // Determine main word direction
        let isMainWordHorizontal = placements.count > 1 && 
            placements.allSatisfy { $0.position.row == placements.first?.position.row }
        
        // Check for perpendicular words only
        for placement in placements {
            let row = placement.position.row
            let col = placement.position.column
            
            // Check perpendicular direction only
            if isMainWordHorizontal {
                // Main word is horizontal, check vertical words
                if let verticalWord = try getWordAtPosition(row: row, column: col, isHorizontal: false) {
                    if !words.contains(where: { Set($0.map { $0.position }) == Set(verticalWord.map { $0.position }) }) {
                        words.append(verticalWord)
                    }
                }
            } else {
                // Main word is vertical, check horizontal words
                if let horizontalWord = try getWordAtPosition(row: row, column: col, isHorizontal: true) {
                    if !words.contains(where: { Set($0.map { $0.position }) == Set(horizontalWord.map { $0.position }) }) {
                        words.append(horizontalWord)
                    }
                }
            }
        }
        
        return words
    }
    
    private func getWordAtPosition(row: Int, column: Int, isHorizontal: Bool) throws -> [WordPlacement]? {
        var word: [WordPlacement] = []
        
        if isHorizontal {
            // Find start of word
            var startCol = column
            while startCol > 0 && board[row][startCol - 1] != nil {
                startCol -= 1
            }
            
            // Build word
            var currentCol = startCol
            while currentCol < columns && board[row][currentCol] != nil {
                if let tileID = board[row][currentCol] {
                    let position = BoardPosition(row: row, column: currentCol)
                    // Find the original placement or create a temporary one
                    // For existing tiles, we need to reconstruct the placement
                    // This is a simplified version - in a real implementation, you'd track this better
                    word.append(WordPlacement(
                        tileID: tileID,
                        position: position,
                        letter: blankTileAssignments[tileID]
                    ))
                }
                currentCol += 1
            }
        } else {
            // Find start of word
            var startRow = row
            while startRow > 0 && board[startRow - 1][column] != nil {
                startRow -= 1
            }
            
            // Build word
            var currentRow = startRow
            while currentRow < rows && board[currentRow][column] != nil {
                if let tileID = board[currentRow][column] {
                    let position = BoardPosition(row: currentRow, column: column)
                    word.append(WordPlacement(
                        tileID: tileID,
                        position: position,
                        letter: blankTileAssignments[tileID]
                    ))
                }
                currentRow += 1
            }
        }
        
        return word.count > 1 ? word : nil
    }
    
    private mutating func drawTiles(for playerIndex: Int, count: Int) throws {
        let tilesToDraw = min(count, tileBag.count)
        guard tilesToDraw > 0 else { return }
        
        let newTiles = Array(tileBag.prefix(tilesToDraw))
        tileBag.removeFirst(tilesToDraw)
        playerRacks[playerIndex].tiles.append(contentsOf: newTiles)
    }
    
    private mutating func advanceToNextPlayer() {
        guard case .waitingForPlayer(let currentPlayerID) = state else { return }
        
        guard let currentIndex = playerRacks.firstIndex(where: { $0.player.id == currentPlayerID }) else {
            return
        }
        
        let nextIndex = (currentIndex + 1) % playerRacks.count
        state = .waitingForPlayer(id: playerRacks[nextIndex].player.id)
    }
    
    private mutating func checkGameEnd() {
        // Game ends when a player uses all their tiles
        for playerRack in playerRacks {
            if playerRack.tiles.isEmpty {
                endGame()
                return
            }
        }
        
        // Game ends when tile bag is empty and all players pass
        if tileBag.isEmpty && consecutivePasses >= playerRacks.count {
            endGame()
        }
    }
    
    private mutating func endGame() {
        // Deduct remaining tile values from each player's score
        for (index, playerRack) in playerRacks.enumerated() {
            var penalty = 0
            for tileID in playerRack.tiles {
                if let tile = tilesMap[tileID] {
                    penalty += tile.pointValue
                }
            }
            playerRacks[index].player.score -= penalty
        }
        
        // Find winner
        let winner = playerRacks.max(by: { $0.player.score < $1.player.score })!.player
        state = .gameComplete(winner: winner)
        ended = .now
    }
}

