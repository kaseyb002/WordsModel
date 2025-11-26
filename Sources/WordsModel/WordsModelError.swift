import Foundation

public enum WordsModelError: Error, Equatable {
    case notEnoughPlayers
    case tooManyPlayers
    case notWaitingForPlayerToAct
    case playerNotFound
    case tileDoesNotExistInPlayersRack
    case tileBagIsEmpty
    case invalidWordPlacement
    case wordDoesNotConnectToExistingTiles
    case firstWordMustUseCenterSquare
    case invalidPosition
    case positionAlreadyOccupied
    case wordNotInDictionary
    case invalidWordFormation
    case gameIsComplete
    case insufficientTilesToExchange
    case cannotPassOnFirstTurn
    case blankTileRequiresLetter
    case nonBlankTileCannotHaveLetter
}

