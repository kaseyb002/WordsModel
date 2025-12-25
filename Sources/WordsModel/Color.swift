import Foundation

public enum Color: String, Equatable, Codable, Sendable, CaseIterable {
    case yellow = "y"
    case blue = "b"
    case green = "g"
    case red = "r"

    public var name: String {
        switch self {
        case .yellow: "Yellow"
        case .blue: "Blue"
        case .green: "Green"
        case .red: "Red"
        }
    }
    
    public var emoji: String {
        switch self {
        case .yellow: "🟡"
        case .blue: "🔵"
        case .green: "🟢"
        case .red: "🔴"
        }
    }
}

