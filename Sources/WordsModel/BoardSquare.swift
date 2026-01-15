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
        // Original word game board layout (15x15)
        var board: [[BoardSquare]] = Array(
            repeating: Array(
                repeating: BoardSquare.empty,
                count: 15
            ),
            count: 15
        )
        
        // Triple word scores - placed in strategic interior positions (not corners)
        let tripleWordPositions: [(Int, Int)] = [
            (2, 2), (2, 12), (4, 4), (4, 10),
            (10, 4), (10, 10), (12, 2), (12, 12)
        ]
        for (row, col) in tripleWordPositions {
            board[row][col] = .tripleWord
        }
        
        // Double word scores - border pattern (not diagonal)
        let doubleWordPositions: [(Int, Int)] = [
            (0, 4), (0, 10), (1, 7), (3, 0), (3, 14),
            (4, 0), (4, 14), (6, 2), (6, 12), (7, 1),
            (7, 13), (8, 2), (8, 12), (10, 0), (10, 14),
            (11, 0), (11, 14), (13, 7), (14, 4), (14, 10)
        ]
        for (row, col) in doubleWordPositions {
            board[row][col] = .doubleWord
        }
        
        // Triple letter scores - cross pattern
        let tripleLetterPositions: [(Int, Int)] = [
            (1, 3), (1, 11), (3, 6), (3, 8),
            (5, 5), (5, 9), (6, 6), (6, 8),
            (8, 6), (8, 8), (9, 5), (9, 9),
            (11, 6), (11, 8), (13, 3), (13, 11)
        ]
        for (row, col) in tripleLetterPositions {
            board[row][col] = .tripleLetter
        }
        
        // Double letter scores - distributed pattern
        let doubleLetterPositions: [(Int, Int)] = [
            (0, 1), (0, 7), (0, 13), (1, 1), (1, 5), (1, 9), (1, 13),
            (2, 5), (2, 9), (3, 2), (3, 4), (3, 10), (3, 12),
            (4, 2), (4, 6), (4, 8), (4, 12), (5, 1), (5, 7), (5, 13),
            (6, 4), (6, 10), (7, 5), (7, 9), (8, 4), (8, 10),
            (9, 1), (9, 7), (9, 13), (10, 2), (10, 6), (10, 8), (10, 12),
            (11, 2), (11, 4), (11, 10), (11, 12), (12, 5), (12, 9),
            (13, 1), (13, 5), (13, 9), (13, 13), (14, 1), (14, 7), (14, 13)
        ]
        for (row, col) in doubleLetterPositions {
            board[row][col] = .doubleLetter
        }
        
        // Center square (starting position)
        board[7][7] = .center
        
        return board
    }
}
