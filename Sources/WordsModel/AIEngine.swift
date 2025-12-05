import Foundation

public enum AIDifficulty: String, CaseIterable, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
}

public struct AIEngine {
    private let difficulty: AIDifficulty
    
    public init(difficulty: AIDifficulty) {
        self.difficulty = difficulty
    }
    
    /// Get the best move for the AI player
    /// Returns a PlaceWordForm if a word can be placed, nil if AI should pass or exchange
    public func getBestMove(for round: Round, playerId: String) async throws -> PlaceWordForm? {
        guard let playerRack = round.playerRack(for: playerId) else {
            return nil
        }
        
        // Find all possible word placements
        let possibleMoves = try await findAllPossibleMoves(round: round, playerRack: playerRack)
        
        guard !possibleMoves.isEmpty else {
            // No valid moves - consider passing or exchanging
            return nil
        }
        
        switch difficulty {
        case .easy:
            return getEasyMove(possibleMoves: possibleMoves)
        case .medium:
            return getMediumMove(possibleMoves: possibleMoves, round: round)
        case .hard:
            return getHardMove(possibleMoves: possibleMoves, round: round, playerId: playerId)
        }
    }
    
    /// Find all possible word placements from the player's rack
    private func findAllPossibleMoves(round: Round, playerRack: PlayerRack) async throws -> [PlaceWordForm] {
        var possibleMoves: [PlaceWordForm] = []
        
        let isFirstWord = round.board.allSatisfy { $0.allSatisfy { $0 == nil } }
        
        if isFirstWord {
            // First word must use center square (7,7)
            let centerPosition = BoardPosition(row: 7, column: 7)
            possibleMoves = try await findMovesFromPosition(
                round: round,
                playerRack: playerRack,
                anchorPosition: centerPosition
            )
        } else {
            // Find all anchor positions (positions adjacent to existing tiles)
            let anchorPositions = findAnchorPositions(round: round)
            
            for anchorPosition in anchorPositions {
                let moves = try await findMovesFromPosition(
                    round: round,
                    playerRack: playerRack,
                    anchorPosition: anchorPosition
                )
                possibleMoves.append(contentsOf: moves)
            }
        }
        
        return possibleMoves
    }
    
    /// Find anchor positions (empty squares adjacent to existing tiles)
    private func findAnchorPositions(round: Round) -> [BoardPosition] {
        var anchors: Set<BoardPosition> = []
        
        for row in 0..<round.rows {
            for col in 0..<round.columns {
                // If this position has a tile, check adjacent empty positions
                if round.board[row][col] != nil {
                    let adjacentPositions = [
                        BoardPosition(row: row - 1, column: col),
                        BoardPosition(row: row + 1, column: col),
                        BoardPosition(row: row, column: col - 1),
                        BoardPosition(row: row, column: col + 1)
                    ]
                    
                    for pos in adjacentPositions {
                        if pos.row >= 0 && pos.row < round.rows &&
                           pos.column >= 0 && pos.column < round.columns &&
                           round.board[pos.row][pos.column] == nil {
                            anchors.insert(pos)
                        }
                    }
                }
            }
        }
        
        return Array(anchors)
    }
    
    /// Find all possible word placements from a specific anchor position
    private func findMovesFromPosition(
        round: Round,
        playerRack: PlayerRack,
        anchorPosition: BoardPosition
    ) async throws -> [PlaceWordForm] {
        var moves: [PlaceWordForm] = []
        
        // Try horizontal words
        let horizontalMoves = try await findWordsInDirection(
            round: round,
            playerRack: playerRack,
            anchorPosition: anchorPosition,
            isHorizontal: true
        )
        moves.append(contentsOf: horizontalMoves)
        
        // Try vertical words
        let verticalMoves = try await findWordsInDirection(
            round: round,
            playerRack: playerRack,
            anchorPosition: anchorPosition,
            isHorizontal: false
        )
        moves.append(contentsOf: verticalMoves)
        
        return moves
    }
    
    /// Find words in a specific direction (horizontal or vertical)
    private func findWordsInDirection(
        round: Round,
        playerRack: PlayerRack,
        anchorPosition: BoardPosition,
        isHorizontal: Bool
    ) async throws -> [PlaceWordForm] {
        var moves: [PlaceWordForm] = []
        
        // Try placing words of different lengths (2-7 tiles)
        for wordLength in 2...min(7, playerRack.tiles.count) {
            // Try all combinations of tiles from rack
            let tileCombinations = generateTileCombinations(
                tiles: playerRack.tiles,
                length: wordLength,
                tilesMap: round.tilesMap
            )
            
            for tileCombo in tileCombinations {
                // Try placing this combination starting at different positions relative to anchor
                let placements = try generatePlacementsForTiles(
                    round: round,
                    tiles: tileCombo,
                    anchorPosition: anchorPosition,
                    isHorizontal: isHorizontal
                )
                
                for placement in placements {
                    // Validate word against dictionary
                    if try await isValidWordPlacement(round: round, placements: placement) {
                        moves.append(PlaceWordForm(placements: placement))
                    }
                }
            }
        }
        
        return moves
    }
    
    /// Generate all combinations of tiles of a given length
    private func generateTileCombinations(
        tiles: [TileID],
        length: Int,
        tilesMap: [TileID: Tile]
    ) -> [[TileID]] {
        guard length <= tiles.count else { return [] }
        
        // Simple approach: generate combinations
        // For efficiency, we'll limit to reasonable combinations
        var combinations: [[TileID]] = []
        
        func generate(current: [TileID], remaining: [TileID], targetLength: Int) {
            if current.count == targetLength {
                combinations.append(current)
                return
            }
            
            guard !remaining.isEmpty else { return }
            
            for (index, tile) in remaining.enumerated() {
                var newCurrent = current
                newCurrent.append(tile)
                var newRemaining = remaining
                newRemaining.remove(at: index)
                generate(current: newCurrent, remaining: newRemaining, targetLength: targetLength)
            }
        }
        
        // Limit combinations for performance (especially for hard difficulty)
        let maxCombinations = difficulty == .hard ? 100 : (difficulty == .medium ? 50 : 20)
        
        generate(current: [], remaining: tiles, targetLength: length)
        
        // Limit and shuffle for variety
        if combinations.count > maxCombinations {
            combinations = Array(combinations.shuffled().prefix(maxCombinations))
        }
        
        return combinations
    }
    
    /// Generate placements for tiles starting from anchor position
    private func generatePlacementsForTiles(
        round: Round,
        tiles: [TileID],
        anchorPosition: BoardPosition,
        isHorizontal: Bool
    ) throws -> [[TilePlacement]] {
        var placements: [[TilePlacement]] = []
        
        // Try placing the word with anchor at different positions within the word
        for anchorIndex in 0..<tiles.count {
            var placement: [TilePlacement] = []
            var valid = true
            
            for (tileIndex, tileID) in tiles.enumerated() {
                let offset = tileIndex - anchorIndex
                let position: BoardPosition
                
                if isHorizontal {
                    position = BoardPosition(
                        row: anchorPosition.row,
                        column: anchorPosition.column + offset
                    )
                } else {
                    position = BoardPosition(
                        row: anchorPosition.row + offset,
                        column: anchorPosition.column
                    )
                }
                
                // Check if position is valid and empty
                if position.row < 0 || position.row >= round.rows ||
                   position.column < 0 || position.column >= round.columns {
                    valid = false
                    break
                }
                
                if round.board[position.row][position.column] != nil {
                    // Position already has a tile - this is okay if it matches
                    // For now, skip this placement
                    valid = false
                    break
                }
                
                let tile = round.tilesMap[tileID]!
                let letter: Tile.Letter? = tile.letter == .blank ? .a : nil // Placeholder for blank
                
                placement.append(TilePlacement(
                    tileID: tileID,
                    position: position,
                    blankLetterUsedAs: letter
                ))
            }
            
            if valid {
                placements.append(placement)
            }
        }
        
        return placements
    }
    
    /// Validate that a word placement forms valid dictionary words
    private func isValidWordPlacement(round: Round, placements: [TilePlacement]) async throws -> Bool {
        // Create a temporary round to test the placement
        var testRound = round
        
        // Place tiles temporarily
        for placement in placements {
            testRound.board[placement.position.row][placement.position.column] = placement.tileID
            if let letter = placement.blankLetterUsedAs,
               let tile = testRound.tilesMap[placement.tileID],
               tile.letter == .blank {
                testRound.blankTileAssignments[placement.tileID] = letter
            }
        }
        
        // Validate all words formed
        let words = try testRound.getAllWordsFormed(placements: placements)
        
        for word in words {
            let wordString = try wordString(from: word, round: testRound)
            let isValidWord = await !WordDictionary.shared.isValid(wordString)
            if wordString.count > 1 && isValidWord {
                return false
            }
        }
        
        return true
    }
    
    /// Convert word placements to string
    private func wordString(from placements: [TilePlacement], round: Round) throws -> String {
        var wordString = ""
        for placement in placements {
            guard let tile = round.tilesMap[placement.tileID] else {
                throw WordPlacementError.tileDoesNotExistInPlayersRack
            }
            
            let letter: Tile.Letter
            if tile.letter == .blank, let assignedLetter = placement.blankLetterUsedAs {
                letter = assignedLetter
            } else {
                letter = tile.letter
            }
            
            wordString.append(letter.rawValue)
        }
        return wordString.uppercased()
    }
    
    // MARK: - Move Selection by Difficulty
    
    /// Easy: Random valid move, sometimes picks high-scoring moves
    private func getEasyMove(possibleMoves: [PlaceWordForm]) -> PlaceWordForm? {
        guard !possibleMoves.isEmpty else { return nil }
        
        // 60% random, 40% highest scoring
        if Double.random(in: 0...1) < 0.6 {
            return possibleMoves.randomElement()
        } else {
            // Return a move with decent score (not necessarily best)
            return possibleMoves.sorted { $0.estimatedScore > $1.estimatedScore }.first
        }
    }
    
    /// Medium: Greedy - picks highest scoring move
    private func getMediumMove(possibleMoves: [PlaceWordForm], round: Round) -> PlaceWordForm? {
        guard !possibleMoves.isEmpty else { return nil }
        
        // Score all moves and pick the best
        let scoredMoves = possibleMoves.map { move in
            (move: move, score: calculateMoveScore(move: move, round: round))
        }
        
        return scoredMoves.max(by: { $0.score < $1.score })?.move
    }
    
    /// Hard: Considers opponent blocking and strategic placement
    private func getHardMove(possibleMoves: [PlaceWordForm], round: Round, playerId: String) -> PlaceWordForm? {
        guard !possibleMoves.isEmpty else { return nil }
        
        // Score moves considering:
        // 1. Immediate score
        // 2. Blocking opponent's high-value spots
        // 3. Opening up future opportunities
        
        let scoredMoves = possibleMoves.map { move in
            var score = calculateMoveScore(move: move, round: round)
            
            // Bonus for using all tiles (bingo)
            if move.placements.count == 7 {
                score += 50
            }
            
            // Bonus for blocking premium squares
            score += calculateBlockingBonus(move: move, round: round)
            
            // Penalty for leaving easy openings for opponent
            score -= calculateOpeningPenalty(move: move, round: round)
            
            return (move: move, score: score)
        }
        
        return scoredMoves.max(by: { $0.score < $1.score })?.move
    }
    
    /// Calculate the score for a move
    private func calculateMoveScore(move: PlaceWordForm, round: Round) -> Double {
        // This is a simplified score - the actual scoring happens in Round.placeWord
        // We estimate based on tile values and multipliers
        var score = 0.0
        
        for placement in move.placements {
            guard let tile = round.tilesMap[placement.tileID] else { continue }
            
            let square = round.boardSquares[placement.position.row][placement.position.column]
            let letterValue: Int
            if tile.letter == .blank, let assignedLetter = placement.blankLetterUsedAs {
                letterValue = assignedLetter.standardPointValue
            } else {
                letterValue = tile.pointValue
            }
            
            score += Double(letterValue * square.multiplier.letter)
        }
        
        // Apply word multipliers (simplified - assumes one word)
        if let firstPlacement = move.placements.first {
            let square = round.boardSquares[firstPlacement.position.row][firstPlacement.position.column]
            score *= Double(square.multiplier.word)
        }
        
        return score
    }
    
    /// Calculate bonus for blocking premium squares
    private func calculateBlockingBonus(move: PlaceWordForm, round: Round) -> Double {
        var bonus = 0.0
        
        for placement in move.placements {
            let square = round.boardSquares[placement.position.row][placement.position.column]
            if square.multiplier.word > 1 || square.multiplier.letter > 1 {
                bonus += 5.0 // Small bonus for using premium squares
            }
        }
        
        return bonus
    }
    
    /// Calculate penalty for leaving openings
    private func calculateOpeningPenalty(move: PlaceWordForm, round: Round) -> Double {
        // Simplified: penalty for placing near edges (easier for opponent)
        var penalty = 0.0
        
        for placement in move.placements {
            let row = placement.position.row
            let col = placement.position.column
            
            // Small penalty for edge placements
            if row < 3 || row > 11 || col < 3 || col > 11 {
                penalty += 1.0
            }
        }
        
        return penalty
    }
}

// MARK: - Helper Extensions

extension PlaceWordForm {
    /// Estimated score for quick sorting (used in easy difficulty)
    fileprivate var estimatedScore: Double {
        // Simple estimation based on number of tiles
        return Double(placements.count * 10)
    }
}

// MARK: - Round Extension for AI

extension Round {
    /// Get all words that would be formed by a placement
    fileprivate func getAllWordsFormed(placements: [TilePlacement]) throws -> [[TilePlacement]] {
        // This mirrors the logic in Round+Actions but for testing
        var words: [[TilePlacement]] = []
        words.append(placements)
        
        // Determine main word direction
        let isMainWordHorizontal = placements.count > 1 &&
            placements.allSatisfy { $0.position.row == placements.first?.position.row }
        
        // Check for perpendicular words
        for placement in placements {
            let row = placement.position.row
            let col = placement.position.column
            
            if isMainWordHorizontal {
                // Check vertical words
                if let verticalWord = try getWordAtPosition(row: row, column: col, isHorizontal: false) {
                    if !words.contains(where: { Set($0.map { $0.position }) == Set(verticalWord.map { $0.position }) }) {
                        words.append(verticalWord)
                    }
                }
            } else {
                // Check horizontal words
                if let horizontalWord = try getWordAtPosition(row: row, column: col, isHorizontal: true) {
                    if !words.contains(where: { Set($0.map { $0.position }) == Set(horizontalWord.map { $0.position }) }) {
                        words.append(horizontalWord)
                    }
                }
            }
        }
        
        return words
    }
    
    /// Get word at a specific position
    private func getWordAtPosition(row: Int, column: Int, isHorizontal: Bool) throws -> [TilePlacement]? {
        var word: [TilePlacement] = []
        
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
                    word.append(TilePlacement(
                        tileID: tileID,
                        position: position,
                        blankLetterUsedAs: blankTileAssignments[tileID]
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
                    word.append(TilePlacement(
                        tileID: tileID,
                        position: position,
                        blankLetterUsedAs: blankTileAssignments[tileID]
                    ))
                }
                currentRow += 1
            }
        }
        
        return word.count > 1 ? word : nil
    }
}

