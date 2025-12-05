import Foundation

public enum WordsModelError: Error, Equatable {
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

public enum WordPlacementError: Error, Equatable {
    case wordDoesNotConnectToExistingTiles
    case tilesNotPlacedInAStraightLine
    case tilesNotPlacedConsecutively
    case invalidWordPlacement
    case invalidWordFormation
    case wordNotInDictionary(word: String)
    case noTilePlacementsFound
    case blankTileRequiresLetter
    case nonBlankTileCannotHaveLetter
    case firstWordMustUseCenterSquare
    case tileDoesNotExistInPlayersRack
    case tileDoesNotExistInTilesMap
}
