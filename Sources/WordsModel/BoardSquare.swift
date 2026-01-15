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
        var board: [[BoardSquare]] = Array(
            repeating: Array(
                repeating: BoardSquare.empty,
                count: 15
            ),
            count: 15
        )
        
        // Triple word scores (corners and edges)
        let tripleWordPositions: [(Int, Int)] = [
            (0, 0), (0, 7), (0, 14),
            (7, 0), (7, 14),
            (14, 0), (14, 7), (14, 14)
        ]
        for (row, col) in tripleWordPositions {
            board[row][col] = .tripleWord
        }
        
        // Double word scores
        let doubleWordPositions: [(Int, Int)] = [
            (1, 1), (1, 13), (2, 2), (2, 12), (3, 3), (3, 11),
            (4, 4), (4, 10), (10, 4), (10, 10), (11, 3), (11, 11),
            (12, 2), (12, 12), (13, 1), (13, 13)
        ]
        for (row, col) in doubleWordPositions {
            board[row][col] = .doubleWord
        }
        
        // Triple letter scores
        let tripleLetterPositions: [(Int, Int)] = [
            (1, 5), (1, 9), (5, 1), (5, 5), (5, 9), (5, 13),
            (9, 1), (9, 5), (9, 9), (9, 13), (13, 5), (13, 9)
        ]
        for (row, col) in tripleLetterPositions {
            board[row][col] = .tripleLetter
        }
        
        // Double letter scores
        let doubleLetterPositions: [(Int, Int)] = [
            (0, 3), (0, 11), (2, 6), (2, 8), (3, 0), (3, 7), (3, 14),
            (6, 2), (6, 6), (6, 8), (6, 12), (7, 3), (7, 11),
            (8, 2), (8, 6), (8, 8), (8, 12), (11, 0), (11, 7), (11, 14),
            (12, 6), (12, 8), (14, 3), (14, 11)
        ]
        for (row, col) in doubleLetterPositions {
            board[row][col] = .doubleLetter
        }
        
        // Center square (starting position)
        board[7][7] = .center
        
        return board
    }
}
