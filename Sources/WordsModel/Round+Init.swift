import Foundation

extension Round {
    public init(
        id: String = UUID().uuidString,
        started: Date = .now,
        rows: Int = 15,
        columns: Int = 15,
        cookedTiles: [Tile]? = nil,
        players: [Player]
    ) throws {
        guard players.count >= 2 else {
            throw WordsModelError.notEnoughPlayers
        }
        guard players.count <= 4 else {
            throw WordsModelError.tooManyPlayers
        }
        
        self.id = id
        self.started = started
        self.rows = rows
        self.columns = columns
        
        // Assign colors to players (red, blue, green, yellow in order)
        let colors: [Color] = [.red, .blue, .green, .yellow]
        var playersWithColors = players
        for (index, player) in playersWithColors.enumerated() {
            playersWithColors[index] = player.changeColor(color: colors[index])
        }
        
        // Initialize tiles
        let allTiles = cookedTiles ?? Tile.standardDistribution().shuffled()
        self.tilesMap = Dictionary(uniqueKeysWithValues: allTiles.map { ($0.id, $0) })
        
        // Initialize board
        self.board = Array(repeating: Array(repeating: nil, count: columns), count: rows)
        self.boardSquares = BoardSquare.standardBoard()
        
        // Deal tiles to players (7 tiles each)
        var remainingTiles = allTiles.map(\.id).shuffled()
        self.playerRacks = try Self.dealTiles(
            to: playersWithColors,
            tileBag: &remainingTiles,
            tilesPerPlayer: 7
        )
        self.tileBag = remainingTiles
        
        // Set initial state
        self.state = .waitingForPlayer(id: playersWithColors.first!.id)
    }
    
    private static func dealTiles(
        to players: [Player],
        tileBag: inout [TileID],
        tilesPerPlayer: Int
    ) throws -> [PlayerRack] {
        var playerRacks: [PlayerRack] = []
        
        for player in players {
            guard tileBag.count >= tilesPerPlayer else {
                throw WordsModelError.tileBagIsEmpty
            }
            let playerTiles = Array(tileBag.prefix(tilesPerPlayer))
            tileBag.removeFirst(tilesPerPlayer)
            
            let playerRack = PlayerRack(
                player: player,
                tiles: playerTiles
            )
            playerRacks.append(playerRack)
        }
        
        return playerRacks
    }
}

