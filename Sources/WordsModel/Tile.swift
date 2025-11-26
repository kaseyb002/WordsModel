import Foundation

public typealias TileID = Int

public struct Tile: Equatable, Codable, Identifiable {
    public let id: TileID
    public let letter: Letter
    public let pointValue: Int
    
    public enum Letter: String, Equatable, Codable, CaseIterable {
        case blank = " "
        case a = "A", b = "B", c = "C", d = "D", e = "E", f = "F", g = "G"
        case h = "H", i = "I", j = "J", k = "K", l = "L", m = "M", n = "N"
        case o = "O", p = "P", q = "Q", r = "R", s = "S", t = "T", u = "U"
        case v = "V", w = "W", x = "X", y = "Y", z = "Z"
        
        public var standardPointValue: Int {
            switch self {
            case .blank: 0
            case .a, .e, .i, .o, .u, .l, .n, .s, .t, .r: 1
            case .d, .g: 2
            case .b, .c, .m, .p: 3
            case .f, .h, .v, .w, .y: 4
            case .k: 5
            case .j, .x: 8
            case .q, .z: 10
            }
        }
    }
    
    public init(
        id: TileID,
        letter: Letter,
        pointValue: Int? = nil
    ) {
        self.id = id
        self.letter = letter
        self.pointValue = pointValue ?? letter.standardPointValue
    }
    
    public static func standardDistribution() -> [Tile] {
        var tiles: [Tile] = []
        var id: TileID = 0
        
        // Standard Scrabble distribution
        let distribution: [(Letter, Int)] = [
            (.blank, 2),
            (.a, 9), (.b, 2), (.c, 2), (.d, 4), (.e, 12), (.f, 2), (.g, 3),
            (.h, 2), (.i, 9), (.j, 1), (.k, 1), (.l, 4), (.m, 2), (.n, 6),
            (.o, 8), (.p, 2), (.q, 1), (.r, 6), (.s, 4), (.t, 6), (.u, 4),
            (.v, 2), (.w, 2), (.x, 1), (.y, 2), (.z, 1)
        ]
        
        for (letter, count) in distribution {
            for _ in 0..<count {
                tiles.append(Tile(id: id, letter: letter))
                id += 1
            }
        }
        
        return tiles
    }
}

