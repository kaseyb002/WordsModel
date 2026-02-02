import Foundation

public enum WordsModelError: Error, Equatable, Sendable {
    case notEnoughPlayers
    case tooManyPlayers
    case notWaitingForPlayerToAct
    case playerNotFound
    case tileBagIsEmpty
    case invalidPosition
    case positionAlreadyOccupied
    case gameIsComplete
    case insufficientTilesToExchange
    case cannotPassOnFirstTurn
}

public enum WordPlacementError: Error, Equatable, Sendable {
    case wordDoesNotConnectToExistingTiles
    case tilesNotPlacedInAStraightLine
    case tilesNotPlacedConsecutively
    case invalidWordPlacement
    case invalidWordFormation
    case wordsNotInDictionary(words: [String])
    case noTilePlacementsFound
    case blankTileRequiresLetter
    case nonBlankTileCannotHaveLetter
    case firstWordMustUseCenterSquare
    case tileDoesNotExistInPlayersRack
    case tileDoesNotExistInTilesMap
}
