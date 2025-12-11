import Foundation

public struct PointMultiplier: Equatable, Codable, Sendable {
    public let letter: Int
    public let word: Int
    
    public init(letter: Int, word: Int) {
        self.letter = letter
        self.word = word
    }
}
