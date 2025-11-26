import Foundation

/// A dictionary for validating words in the Words game.
/// Uses the SOWPODS word list (the official Scrabble dictionary).
public actor WordDictionary {
    public static let shared = WordDictionary()
    
    private var validWords: Set<String>?
    
    private init() {}
    
    /// Checks if a word is valid (exists in the dictionary).
    /// - Parameter word: The word to check (case-insensitive).
    /// - Returns: `true` if the word is valid, `false` otherwise.
    public func isValid(_ word: String) -> Bool {
        let uppercaseWord = word.uppercased()
        return loadWords().contains(uppercaseWord)
    }
    
    /// Loads the dictionary words, loading from file if not already loaded.
    /// - Returns: A Set of valid words in uppercase.
    private func loadWords() -> Set<String> {
        if let words = validWords {
            return words
        }
        
        // Load from sowpods.txt resource
        guard let filePath = Bundle.module.path(forResource: "sowpods", ofType: "txt"),
              let content = try? String(contentsOfFile: filePath, encoding: .utf8) else {
            // If dictionary can't be loaded, return empty set (will reject all words)
            // This is safer than accepting all words
            validWords = Set<String>()
            return validWords!
        }
        
        let words = content
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { $0.uppercased() }
        
        validWords = Set(words)
        return validWords!
    }
}

