import Foundation

public enum BoardSquare: Equatable, Codable, Sendable {
    case empty
    case doubleLetter
    case tripleLetter
    case doubleWord
    case tripleWord
    case center // Starting position
    
    public var multiplier: PointMultiplier {
        switch self {
        case .empty, .center:
            return PointMultiplier(letter: 1, word: 1)
            
        case .doubleLetter:
            return PointMultiplier(letter: 2, word: 1)
            
        case .tripleLetter:
            return PointMultiplier(letter: 3, word: 1)
            
        case .doubleWord:
            return PointMultiplier(letter: 1, word: 2)
            
        case .tripleWord:
            return PointMultiplier(letter: 1, word: 3)
        }
    }
    
    public static func standardBoard() -> [[BoardSquare]] {
        // Standard Scrabble board layout (15x15)
        // TW .. .. DL .. TL .. TW .. TL .. DL .. .. TW (and symmetric)
        var board: [[BoardSquare]] = Array(
            repeating: Array(
                repeating: BoardSquare.empty,
                count: 15
            ),
            count: 15
        )
        
        // Triple word scores (corners and mid-edges)
        let tripleWordPositions: [(Int, Int)] = [
            (0, 0), (0, 7), (0, 14),
            (7, 0), (7, 14),
            (14, 0), (14, 7), (14, 14)
        ]
        for (row, col) in tripleWordPositions {
            board[row][col] = .tripleWord
        }
        
        // Double word scores (diamond/cross pattern)
        let doubleWordPositions: [(Int, Int)] = [
            (2, 6), (3, 6), (3, 8), (4, 5), (4, 9), (5, 4), (5, 9),
            (6, 3), (6, 10), (7, 2), (7, 12), (8, 3), (8, 10),
            (9, 4), (9, 9), (10, 5), (10, 9), (11, 6), (11, 8), (12, 6)
        ]
        for (row, col) in doubleWordPositions {
            board[row][col] = .doubleWord
        }
        
        // Triple letter scores
        let tripleLetterPositions: [(Int, Int)] = [
            (0, 5), (0, 9), (1, 4), (1, 9), (2, 3), (2, 10), (3, 2), (3, 11),
            (4, 1), (4, 7), (4, 12), (5, 0), (5, 6), (5, 8), (5, 13),
            (6, 5), (6, 8), (7, 4), (7, 10), (8, 5), (8, 8),
            (9, 0), (9, 6), (9, 8), (9, 13), (10, 1), (10, 7), (10, 12),
            (11, 2), (11, 11), (12, 3), (12, 10), (13, 4), (13, 9),
            (14, 5), (14, 9)
        ]
        for (row, col) in tripleLetterPositions {
            board[row][col] = .tripleLetter
        }
        
        // Double letter scores
        let doubleLetterPositions: [(Int, Int)] = [
            (0, 3), (0, 11), (1, 2), (1, 12), (2, 1), (2, 13),
            (3, 0), (3, 7), (3, 14), (6, 6), (7, 6), (7, 8), (8, 6),
            (11, 0), (11, 7), (11, 14), (12, 1), (12, 13), (13, 2), (13, 12),
            (14, 3), (14, 11)
        ]
        for (row, col) in doubleLetterPositions {
            board[row][col] = .doubleLetter
        }
        
        // Center square (starting position)
        board[7][7] = .center
        
        return board
    }
}
