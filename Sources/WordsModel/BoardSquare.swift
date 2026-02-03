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
        // Standard Scrabble-style board layout (15x15)
        // DL .. .. TW .. TL .. TL .. TW .. .. DL .. .. (and symmetric)
        var board: [[BoardSquare]] = Array(
            repeating: Array(
                repeating: BoardSquare.empty,
                count: 15
            ),
            count: 15
        )
        
        // Triple word scores
        let tripleWordPositions: [(Int, Int)] = [
            (0, 3), (0, 9), (3, 0), (3, 12),
            (11, 0), (11, 12), (14, 3), (14, 9)
        ]
        for (row, col) in tripleWordPositions {
            board[row][col] = .tripleWord
        }
        
        // Double word scores
        let doubleWordPositions: [(Int, Int)] = [
            (1, 4), (1, 10), (3, 6), (5, 1), (5, 13),
            (7, 2), (7, 12), (9, 1), (9, 13), (11, 6),
            (13, 4), (13, 10)
        ]
        for (row, col) in doubleWordPositions {
            board[row][col] = .doubleWord
        }
        
        // Triple letter scores
        let tripleLetterPositions: [(Int, Int)] = [
            (0, 5), (0, 7), (3, 3), (3, 9), (5, 5), (5, 9),
            (6, 0), (6, 14), (8, 0), (8, 14), (9, 5), (9, 9),
            (11, 3), (11, 9), (14, 5), (14, 7)
        ]
        for (row, col) in tripleLetterPositions {
            board[row][col] = .tripleLetter
        }
        
        // Double letter scores
        let doubleLetterPositions: [(Int, Int)] = [
            (0, 0), (0, 12), (1, 1), (1, 13), (2, 2), (2, 5), (2, 8), (2, 11),
            (4, 4), (4, 7), (4, 10), (6, 5), (6, 7), (6, 9),
            (7, 5), (7, 9), (8, 5), (8, 7), (8, 9),
            (10, 4), (10, 7), (10, 10), (12, 2), (12, 5), (12, 8), (12, 11),
            (13, 1), (13, 13), (14, 0), (14, 12)
        ]
        for (row, col) in doubleLetterPositions {
            board[row][col] = .doubleLetter
        }
        
        // Center square (starting position)
        board[7][7] = .center
        
        return board
    }
}
