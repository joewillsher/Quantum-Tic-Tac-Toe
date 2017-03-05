
import UIKit
import Model
import GameplayKit


var model = GameModel()
model.beginTurn()



























/*
GKGameModelPlayer is used to represent one player in the game. This protocol is so simple we already implemented it: all you need to do is make sure your player class has a playerId integer. It's used to identify a player uniquely inside the AI.
*/
class PlayerClass: NSObject, GKGameModelPlayer {
    
    let player: Player
    
    var playerId: Int {
        return player == .O ? 0 : 1
    }
    
    init(player: Player = .O) { self.player = player }
}

/*
GKGameModelUpdate is used to represent one possible move in the game. For us, that means storing a column number to represent a piece being played there. This protocol requires that you also store a value integer, which is used to rank all possible results by quality to help GameplayKit make a good choice.
*/
class MoveClass: NSObject, GKGameModelUpdate {
    
    var value: Int = 0
}

class QuantumMoveClass: MoveClass {
    
    let positions: (BoardPosition, BoardPosition)
    
    init(pos1: BoardPosition, pos2: BoardPosition) {
        positions = (pos1, pos2)
    }
    
}
class ClassicalMoveClass: MoveClass {
    
    let piece: QuantumPlayer
    let position: BoardPosition
    
    init(player: QuantumPlayer, pos: BoardPosition) {
        piece = player
        position = pos
    }
    
}



/*
GKGameModel is used to represent the state of play, which means it needs to know where all the game pieces are, who the players are, what happens after each move is made, and what the score for a player is given any state.
*/
class ModelClass: NSObject, GKGameModel {
    
    var players: [GKGameModelPlayer]?
    var activePlayer: GKGameModelPlayer? {
        return players?[gameModel.count % 2]
    }
    
    var gameModel = GameModel()
    
    override init() {
        self.players = [PlayerClass(player: .O), PlayerClass(player: .X)]
    }
    
    required public convenience init(model: ModelClass) {
        self.init()
        setGameModel(model)
    }
    
    
    /// Returns possble moves
    public func gameModelUpdatesForPlayer(player: GKGameModelPlayer) -> [GKGameModelUpdate]? {
        guard let p = player as? PlayerClass else { return [] }
        
        if case .Win = gameModel.userHasWon() { return [] }
        if gameModel.cannotWin() { return [] }
        
        if let lastPieces = gameModel.lastPieces where gameModel.cyclesPresentForPiece((p.player, gameModel.count)) {
            
            let pos = gameModel.gameBoard.locationsForPiece(lastPieces.0)
            return [ClassicalMoveClass(player: lastPieces.0, pos: pos[0]), ClassicalMoveClass(player: lastPieces.0, pos: pos[1]) ]
        }
        
        let positions = gameModel.gameBoard.boardArray
            .enumerate()
            .filter { i, x in if case .Quantum = x { return true } else { return false } }
            .map { i, _ in (i%3, i/3) }
        
        var moves = [QuantumMoveClass]()
        
        for (i, pos) in positions.enumerate() {
            
            for x in i..<positions.count where x > i {
                let pos2 = positions[x]
                moves.append(QuantumMoveClass(pos1: pos, pos2: pos2))
            }
        }
        
        return moves
    }
    
    
    
    /// Returns numeric score for current board
    func scoreForPlayer(player: GKGameModelPlayer) -> Int {
        guard let p = player as? PlayerClass else { fatalError() }
        
        // handle win/lose case
        if case let .Win(player, _) = gameModel.userHasWon() {
            return player == p.player ? 100 : -100
        }
        
        func has2matches(row: [Tile]) -> Bool { return row.filter {$0 != Tile.Empty}.count == 2 }
        
        let rows = gameModel.gameBoard.rows()
            .filter(has2matches)
            .flatMap {$0.allElementsEqual() }
        let cols = gameModel.gameBoard.columns()
            .filter(has2matches)
            .flatMap {$0.allElementsEqual() }
        let diagonals = gameModel.gameBoard.diagonals()
            .filter(has2matches)
            .flatMap {$0.allElementsEqual() }
        
        let wins = (rows + cols + diagonals)
            .filter { $0 == Tile.Classical(p.player) }
            .count
        let loses = (rows + cols + diagonals)
            .filter { $0 != Tile.Classical(p.player) }
            .count
        
        // handle 1 or 2 possible wins in next round
        switch (wins, loses) {
        case (1, 0):    return  40
        case (2, 0):    return  70
        case (0, 1):    return -40
        case (0, 2):    return -80
        case (1, 2):    return -30
        case (2, 1):    return  30
        case let (a, b) where a > b:  return 40
        default: break
        }
        
        // handle quantum pieces
        
        
        
        
        return 0
    }
    
    
    func applyGameModelUpdate(gameModelUpdate: GKGameModelUpdate) {
        
        switch (gameModelUpdate as? QuantumMoveClass, gameModelUpdate as? ClassicalMoveClass) {
        case let (quantumMove?, _):
            gameModel.playMovesAt(quantumMove.positions)
            
        case let (_, classicalMove?):
            gameModel.collapseCyclesForPiece(classicalMove.piece, at: classicalMove.position)
            
        default:
            fatalError()
        }
        gameModel.count++
        
    }
    
    
    func setGameModel(gameModel: GKGameModel) {
        guard let model = gameModel as? ModelClass else { fatalError() }
        
        self.gameModel.count = model.gameModel.count
        self.gameModel.gameBoard = model.gameModel.gameBoard
        self.gameModel.lastPieces = model.gameModel.lastPieces
        self.players = model.players
    }
    
    func isWinForPlayer(player: GKGameModelPlayer) -> Bool {
        guard let p = player as? PlayerClass, case let .Win(player, _) = gameModel.userHasWon() else { fatalError() }
        return player == p.player
    }
    
    func isLossForPlayer(player: GKGameModelPlayer) -> Bool {
        guard let op = players?[player.playerId+1 % 2] else { fatalError() }
        return isWinForPlayer(op)
    }
    
    func copyWithZone(zone: NSZone) -> AnyObject {
        return self.dynamicType.init(model: self)
    }
}

let mc = ModelClass()
if let p = mc.players?[0] {
    let s = mc.scoreForPlayer(p)
}









