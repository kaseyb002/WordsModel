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
        // Standard Scrabble board layout (15x15) — matches spreadsheet
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
            (0, 3), (0, 11),
            (3, 0), (3, 14),
            (11, 0), (11, 14),
            (14, 3), (14, 11),
        ]
        for (row, col) in tripleWordPositions {
            board[row][col] = .tripleWord
        }
        
        // Double word scores (diamond/cross pattern)
        let doubleWordPositions: [(Int, Int)] = [
            (1, 5), (1, 9),
            (3, 7),
            (5, 1), (5, 13),
            (7, 3), (7, 11),
            (9, 1), (9, 13),
            (11, 7),
            (13, 5), (13, 9),
        ]
        for (row, col) in doubleWordPositions {
            board[row][col] = .doubleWord
        }
        
        // Triple letter scores
        let tripleLetterPositions: [(Int, Int)] = [
            (6, 0), (8, 0)
        ]
        for (row, col) in tripleLetterPositions {
            board[row][col] = .tripleLetter
        }
        
        // Double letter scores (2L — light blue)
        let doubleLetterPositions: [(Int, Int)] = [
            (0, 0), (0, 14), (1, 2), (1, 12), (2, 1), (2, 4), (2, 10), (2, 13),
            (4, 2), (4, 6), (4, 7), (4, 12), (6, 4), (6, 7), (6, 10),
            (7, 6), (7, 8), (8, 4), (8, 7), (8, 10),
            (10, 2), (10, 6), (10, 7), (10, 12), (12, 1), (12, 4), (12, 10), (12, 13),
            (13, 2), (13, 12), (14, 0), (14, 14)
        ]
        for (row, col) in doubleLetterPositions {
            board[row][col] = .doubleLetter
        }
        
        // Center square (starting position)
        board[7][7] = .center
        
        return board
    }
}
