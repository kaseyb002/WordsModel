import Foundation

extension Round {
    public mutating func placeWord(form: PlaceWordForm) async throws {
        guard case .waitingForPlayer(let currentPlayerID) = state else {
            throw WordsModelError.notWaitingForPlayerToAct
        }
        
        guard let currentPlayerIndex: Int = playerRacks.firstIndex(where: { $0.player.id == currentPlayerID }) else {
            throw WordsModelError.playerNotFound
        }
        
        let result: WordPlacementResult = try await wordPlacementResult(form: form)
        
        // Place tiles on board
        var blankAssignments: [TileID: Tile.Letter] = [:]
        for placement in form.placements {
            board[placement.position.row][placement.position.column] = placement.tileID
            
            // Handle blank tiles
            if let letter = placement.blankLetterUsedAs,
               let tile = tilesMap[placement.tileID],
               tile.letter == .blank {
                blankTileAssignments[placement.tileID] = letter
                blankAssignments[placement.tileID] = letter
            }
            
            // Remove tile from player's rack
            guard let tileIndex = playerRacks[currentPlayerIndex].tiles.firstIndex(of: placement.tileID) else {
                throw WordPlacementError.tileDoesNotExistInPlayersRack
            }
            playerRacks[currentPlayerIndex].tiles.remove(at: tileIndex)
        }
        
        // Calculate score
        playerRacks[currentPlayerIndex].player.score += result.points
        
        // Draw new tiles
        try drawTiles(for: currentPlayerIndex, count: form.placements.count)
        
        // Reset consecutive passes
        consecutivePasses = 0
        
        // Log action
        log.append(.init(
            playerId: currentPlayerID,
            action: .placeWord(placements: form.placements, score: result.points),
            timestamp: .now
        ))
        
        // Check for game end conditions
        checkGameEnd()
        
        // Advance to next player
        advanceToNextPlayer()
    }
    
    public func wordPlacementResult(form: PlaceWordForm) async throws -> WordPlacementResult {
        guard case .waitingForPlayer(let currentPlayerID) = state else {
            throw WordsModelError.notWaitingForPlayerToAct
        }
        
        guard let currentPlayerIndex: Int = playerRacks.firstIndex(where: { $0.player.id == currentPlayerID }) else {
            throw WordsModelError.playerNotFound
        }
        
        try validateTilePlacements(form.placements, currentPlayerIndex: currentPlayerIndex)
        
        try await validateWordsAgainstDictionary(placements: form.placements)
        
        let score: Int = try calculateScore(placements: form.placements)
        
        return WordPlacementResult(
            tilePlacements: form.placements,
            points: score
        )
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
        if consecutivePasses >= Constants.endOnConsecutivePasses {
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
                throw WordPlacementError.tileDoesNotExistInPlayersRack
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
    
    private func validateTilePlacements(
        _ placements: [TilePlacement],
        currentPlayerIndex: Int
    ) throws {
        guard !placements.isEmpty else {
            throw WordPlacementError.noTilePlacementsFound
        }
        
        let playerTileIDs: Set<TileID> = Set(playerRacks[currentPlayerIndex].tiles)
        for placement in placements {
            guard playerTileIDs.contains(placement.tileID) else {
                throw WordPlacementError.tileDoesNotExistInPlayersRack
            }
            
            guard let tile: Tile = tilesMap[placement.tileID] else {
                throw WordPlacementError.tileDoesNotExistInTilesMap
            }
            
            switch tile.letter {
            case .blank:
                guard let assignedLetter: Tile.Letter = placement.blankLetterUsedAs,
                      assignedLetter != .blank
                else {
                    throw WordPlacementError.blankTileRequiresLetter
                }
                
            default:
                guard placement.blankLetterUsedAs == nil else {
                    throw WordPlacementError.nonBlankTileCannotHaveLetter
                }
            }
            
            guard placement.position.row >= 0 && placement.position.row < rows,
                  placement.position.column >= 0 && placement.position.column < columns
            else {
                throw WordsModelError.invalidPosition
            }
            
            guard board[placement.position.row][placement.position.column] == nil else {
                throw WordsModelError.positionAlreadyOccupied
            }
        }
        
        try validateWordFormation(placements: placements)
    }
    
    private func validateWordFormation(placements: [TilePlacement]) throws {
        guard placements.count > 1 else { return }
        
        // Check if all placements are in a straight line (horizontal or vertical)
        let sortedByRow: [TilePlacement] = placements.sorted { $0.position.row < $1.position.row || ($0.position.row == $1.position.row && $0.position.column < $1.position.column) }
        let sortedByCol: [TilePlacement] = placements.sorted { $0.position.column < $1.position.column || ($0.position.column == $1.position.column && $0.position.row < $1.position.row) }
        
        // Check if horizontal
        let isHorizontal: Bool = sortedByRow.allSatisfy { $0.position.row == sortedByRow.first?.position.row }
        let isVertical: Bool = sortedByCol.allSatisfy { $0.position.column == sortedByCol.first?.position.column }
        
        guard isHorizontal || isVertical else {
            throw WordPlacementError.tilesNotPlacedInAStraightLine
        }
        
        // Check if consecutive (accounting for existing board tiles between placements)
        if isHorizontal {
            let columns: [Int] = sortedByRow.map { $0.position.column }.sorted()
            let row = sortedByRow.first!.position.row
            let minCol = columns.first!
            let maxCol = columns.last!
            
            // Check that all positions between min and max are either:
            // 1. One of the new placements, OR
            // 2. Already occupied by an existing board tile
            for col in minCol...maxCol {
                let isNewPlacement = columns.contains(col)
                let hasExistingTile = board[row][col] != nil
                guard isNewPlacement || hasExistingTile else {
                    throw WordPlacementError.tilesNotPlacedConsecutively
                }
            }
        } else {
            let rows: [Int] = sortedByCol.map { $0.position.row }.sorted()
            let col = sortedByCol.first!.position.column
            let minRow = rows.first!
            let maxRow = rows.last!
            
            // Check that all positions between min and max are either:
            // 1. One of the new placements, OR
            // 2. Already occupied by an existing board tile
            for row in minRow...maxRow {
                let isNewPlacement = rows.contains(row)
                let hasExistingTile = board[row][col] != nil
                guard isNewPlacement || hasExistingTile else {
                    throw WordPlacementError.tilesNotPlacedConsecutively
                }
            }
        }
        
        let isFirstWord: Bool = board.allSatisfy { $0.allSatisfy { $0 == nil } }
        if isFirstWord {
            let centerPosition: BoardPosition = .init(
                row: 7,
                column: 7
            )
            guard placements.contains(where: { $0.position == centerPosition }) else {
                throw WordPlacementError.firstWordMustUseCenterSquare
            }
        } else {
            guard wordConnectsToExistingTiles(placements: placements) else {
                throw WordPlacementError.wordDoesNotConnectToExistingTiles
            }
        }
    }
    
    private func wordConnectsToExistingTiles(placements: [TilePlacement]) -> Bool {
        for placement in placements {
            let row: Int = placement.position.row
            let col: Int = placement.position.column
            
            // Check adjacent positions
            let adjacentPositions: [(Int, Int)] = [
                (row - 1, col), (row + 1, col),
                (row, col - 1), (row, col + 1)
            ]
            
            for (adjacentRow, adjacentCol) in adjacentPositions {
                if adjacentRow >= 0 && adjacentRow < rows && adjacentCol >= 0 && adjacentCol < columns {
                    if board[adjacentRow][adjacentCol] != nil {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    private func calculateScore(placements: [TilePlacement]) throws -> Int {
        var totalScore = 0
        
        // Get all words formed (main word + any perpendicular words)
        let words: [[TilePlacement]] = try getAllWordsThatWillBeFormed(placements: placements)
        
        // Ensure at least one word is formed (defensive check)
        guard !words.isEmpty else {
            throw WordPlacementError.invalidWordPlacement
        }
        
        for word in words {
            var wordScore = 0
            var wordMultiplierForThisWord = 1
            
            for placement in word {
                guard let tile = tilesMap[placement.tileID] else {
                    throw WordPlacementError.tileDoesNotExistInPlayersRack
                }
                
                let square = boardSquares[placement.position.row][placement.position.column]
                let multipliers = square.multiplier
                
                // Determine letter value (use assigned letter for blanks)
                let letterValue: Int
                if tile.letter == .blank, let assignedLetter = placement.blankLetterUsedAs {
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
    
    private func validateWordsAgainstDictionary(placements: [TilePlacement]) async throws {
        let letterPlacementArrays: [[TilePlacement]] = try getAllWordsThatWillBeFormed(placements: placements)
        
        // Ensure at least one word is formed
        guard !letterPlacementArrays.isEmpty else {
            throw WordPlacementError.invalidWordPlacement
        }
        
        // Convert each word placement array to a word string and validate
        for letterPlacements in letterPlacementArrays {
            let wordString = try wordString(from: letterPlacements)
            
            // Reject single-letter words (not allowed in Scrabble)
            if wordString.count <= 1 {
                throw WordPlacementError.invalidWordPlacement
            }
            
            if await !WordDictionary.shared.isValid(wordString) {
                throw WordPlacementError.wordNotInDictionary(word: wordString)
            }
        }
    }
    
    /// Get all words that will be formed (including perpendicular words with existing tiles)
    /// Searches left/right and up/down from each placement until hitting empty spaces
    private func getAllWordsThatWillBeFormed(placements: [TilePlacement]) throws -> [[TilePlacement]] {
        var words: [[TilePlacement]] = []
        var visitedWordPositions: Set<Set<BoardPosition>> = []
        
        // Create a map of positions to tile placements for quick lookup
        var positionToPlacement: [BoardPosition: TilePlacement] = [:]
        
        // Add new placements to the map
        for placement in placements {
            positionToPlacement[placement.position] = placement
        }
        
        // Add existing board tiles to the map
        for row in 0..<rows {
            for col in 0..<columns {
                if let tileID = board[row][col] {
                    let position = BoardPosition(row: row, column: col)
                    // Only add if not already in new placements
                    if positionToPlacement[position] == nil {
                        positionToPlacement[position] = TilePlacement(
                            tileID: tileID,
                            position: position,
                            blankLetterUsedAs: blankTileAssignments[tileID]
                        )
                    }
                }
            }
        }
        
        // For each new placement, check horizontal and vertical words
        for placement in placements {
            let startRow = placement.position.row
            let startCol = placement.position.column
            
            // Build horizontal word (search left, then right)
            if let horizontalWord = try buildWordInDirection(
                startRow: startRow,
                startCol: startCol,
                isHorizontal: true,
                positionToPlacement: positionToPlacement
            ) {
                let wordPositions = Set(horizontalWord.map { $0.position })
                if !visitedWordPositions.contains(wordPositions) && horizontalWord.count > 1 {
                    words.append(horizontalWord)
                    visitedWordPositions.insert(wordPositions)
                }
            }
            
            // Build vertical word (search up, then down)
            if let verticalWord = try buildWordInDirection(
                startRow: startRow,
                startCol: startCol,
                isHorizontal: false,
                positionToPlacement: positionToPlacement
            ) {
                let wordPositions = Set(verticalWord.map { $0.position })
                if !visitedWordPositions.contains(wordPositions) && verticalWord.count > 1 {
                    words.append(verticalWord)
                    visitedWordPositions.insert(wordPositions)
                }
            }
        }
        
        return words
    }
    
    /// Builds a word by searching in one direction until hitting empty spaces
    /// For horizontal: searches left then right
    /// For vertical: searches up then down
    private func buildWordInDirection(
        startRow: Int,
        startCol: Int,
        isHorizontal: Bool,
        positionToPlacement: [BoardPosition: TilePlacement]
    ) throws -> [TilePlacement]? {
        var word: [TilePlacement] = []
        
        if isHorizontal {
            // Search left until we hit an empty space
            var leftmostCol = startCol
            while leftmostCol > 0 {
                let pos = BoardPosition(row: startRow, column: leftmostCol - 1)
                if positionToPlacement[pos] != nil {
                    leftmostCol -= 1
                } else {
                    break
                }
            }
            
            // Build word from left to right until we hit an empty space
            var currentCol = leftmostCol
            while currentCol < columns {
                let pos = BoardPosition(row: startRow, column: currentCol)
                if let placement = positionToPlacement[pos] {
                    word.append(placement)
                    currentCol += 1
                } else {
                    break
                }
            }
        } else {
            // Search up until we hit an empty space
            var topmostRow = startRow
            while topmostRow > 0 {
                let pos = BoardPosition(row: topmostRow - 1, column: startCol)
                if positionToPlacement[pos] != nil {
                    topmostRow -= 1
                } else {
                    break
                }
            }
            
            // Build word from top to bottom until we hit an empty space
            var currentRow = topmostRow
            while currentRow < rows {
                let pos = BoardPosition(row: currentRow, column: startCol)
                if let placement = positionToPlacement[pos] {
                    word.append(placement)
                    currentRow += 1
                } else {
                    break
                }
            }
        }
        
        // Return word only if it has more than one tile
        return word.count > 1 ? word : nil
    }
    
    private func wordString(from placements: [TilePlacement]) throws -> String {
        // Sort placements by position to ensure correct word order
        // Determine if word is horizontal or vertical
        let isHorizontal = placements.count > 1 && 
            placements.allSatisfy { $0.position.row == placements.first?.position.row }
        
        let sortedPlacements: [TilePlacement]
        if isHorizontal {
            // Sort left-to-right (by column)
            sortedPlacements = placements.sorted { $0.position.column < $1.position.column }
        } else {
            // Sort top-to-bottom (by row)
            sortedPlacements = placements.sorted { $0.position.row < $1.position.row }
        }
        
        var wordString = ""
        for placement in sortedPlacements {
            guard let tile = tilesMap[placement.tileID] else {
                throw WordPlacementError.tileDoesNotExistInPlayersRack
            }
            
            // Use assigned letter for blanks, otherwise use tile's letter
            let letter: Tile.Letter
            if tile.letter == .blank, let assignedLetter = placement.blankLetterUsedAs {
                letter = assignedLetter
            } else {
                letter = tile.letter
            }
            
            wordString.append(letter.rawValue)
        }
        // Return uppercase to match dictionary format
        return wordString.uppercased()
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
        if tileBag.isEmpty && consecutivePasses >= Constants.endOnConsecutivePasses {
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

