import Foundation

public enum Color: String, Equatable, Codable, Sendable, CaseIterable {
    case red = "r"
    case blue = "b"
    case green = "g"
    case yellow = "y"
    
    public var name: String {
        switch self {
        case .red: "Red"
        case .blue: "Blue"
        case .green: "Green"
        case .yellow: "Yellow"
        }
    }
    
    public var emoji: String {
        switch self {
        case .red: "🔴"
        case .blue: "🔵"
        case .green: "🟢"
        case .yellow: "🟡"
        }
    }
}

