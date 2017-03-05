//
//  AI.swift
//  Quantum Tic-Tac-Toe
//
//  Created by Josef Willsher on 24/08/2015.
//  Copyright © 2015 Josef Willsher. All rights reserved.
//

import GameplayKit

/*
GKGameModelPlayer is used to represent one player in the game. This protocol is so simple we already implemented it: all you need to do is make sure your player class has a playerId integer. It's used to identify a player uniquely inside the AI.
*/
public class PlayerClass: NSObject, GKGameModelPlayer {
    
    public let player: Player
    
    public var playerId: Int {
        return player == .o ? 0 : 1
    }
    
    public init(player: Player = .o) { self.player = player }
}

/*
GKGameModelUpdate is used to represent one possible move in the game. For us, that means storing a column number to represent a piece being played there. This protocol requires that you also store a value integer, which is used to rank all possible results by quality to help GameplayKit make a good choice.
*/
public class MoveClass: NSObject, GKGameModelUpdate {
    
    public var value: Int = 0
}

public class QuantumMoveClass: MoveClass {
    
    public let positions: (BoardPosition, BoardPosition)
    
    public init(pos1: BoardPosition, pos2: BoardPosition) {
        positions = (pos1, pos2)
    }
    
}
public class ClassicalMoveClass: MoveClass {
    
    public let piece: QuantumPlayer
    public let position: BoardPosition
    
    public init(player: QuantumPlayer, pos: BoardPosition) {
        piece = player
        position = pos
    }
    
}



/*
GKGameModel is used to represent the state of play, which means it needs to know where all the game pieces are, who the players are, what happens after each move is made, and what the score for a player is given any state.
*/
public class ModelClass: NSObject, GKGameModel {
    
    public var players: [GKGameModelPlayer]?
    public var activePlayer: GKGameModelPlayer? {
        return players?[gameModel.count % 2]
    }
    
    public var gameModel = GameModel()
    
    public override init() {
        self.players = [PlayerClass(player: .o), PlayerClass(player: .x)]
    }
    
    required public convenience init(_ model: ModelClass) {
        self.init()
        setGameModel(model)
    }
    
    
    /// Returns possble moves
    public func gameModelUpdates(for player: GKGameModelPlayer) -> [GKGameModelUpdate]? {
        guard player is PlayerClass else { return [] }
        
        if case .win = gameModel.userHasWon() { return [] }
        if gameModel.cannotWin() { return [] }
        
        if let lastPieces = gameModel.lastPieces, gameModel.cyclesPresent(for: (gameModel.player.other(), gameModel.count-1)) {
            
            let pos = gameModel.gameBoard.locations(of: lastPieces.0)
            return [ClassicalMoveClass(player: lastPieces.0, pos: pos[0]), ClassicalMoveClass(player: lastPieces.0, pos: pos[1]) ]
        }
        
        let positions = gameModel.gameBoard.boardArray
            .enumerated()
            .filter { i, x in if case .classical = x { return false } else { return true } }
            .map { i, _ in (i%3, i/3) }
        
        var moves = [QuantumMoveClass]()
        
        for (i, pos) in positions.enumerated() {
            
            for x in i..<positions.count where x > i {
                let pos2 = positions[x]
                moves.append(QuantumMoveClass(pos1: pos, pos2: pos2))
            }
        }
        
        return moves
    }
    


    /// Returns numeric score for current board
    public func score(for player: GKGameModelPlayer) -> Int {
        guard let p = player as? PlayerClass else { fatalError() }
        
        // handle win/lose case
        
        switch gameModel.userHasWon().winType() {
        case let .win(player):
            return player == p.player ? 100 : -100

        case let .doubleWin(player):
            return player == p.player ? 150 : -150

        case let .narrowWin(player):
            return player == p.player ? 90 : -90
            
        case .draw:
            break
        }
        
        func has2matches(_ row: [Tile]) -> Bool { return row.filter {$0 != Tile.empty}.count == 2 }
        func isClassical(_ tile: Tile) -> Bool { return tile == Tile.classical((p.player, 0)) }
        
        let rows = gameModel.gameBoard.rows()
            .filter(has2matches)
            .flatMap {$0.allElementsEqual() }
        let cols = gameModel.gameBoard.columns()
            .filter(has2matches)
            .flatMap {$0.allElementsEqual() }
        let diagonals = gameModel.gameBoard.diagonals()
            .filter(has2matches)
            .flatMap {$0.allElementsEqual() }
        
        let wins = (rows + cols + diagonals).filter(isClassical).count
        let loses = (rows + cols + diagonals).filter(isClassical).count
        
        // handle 1 or 2 possible wins in next round
        switch (wins, loses) {
        case (1, 0):    return  60
        case (2, 0):    return  70
        case (0, 1):    return -70
        case (0, 2):    return -80
        case (1, 2):    return -30
        case (2, 1):    return  30
        case (1, 1):    return -10
        case let (a, b) where a > b:  return 40
        default: break
        }
        
        // handle quantum pieces
        
        let tot = gameModel.gameBoard.boardArray.filter(isClassical).count
        
        let rand = Int(arc4random_uniform(9))
        if tot >= rand-1 { return 0 }
        
        return 5
    }
    
    
    public func apply(_ gameModelUpdate: GKGameModelUpdate) {
        
        switch gameModelUpdate {
        case let quantumMove as QuantumMoveClass:
            gameModel.playMoves(at: quantumMove.positions)
            
        case let classicalMove as ClassicalMoveClass:
            gameModel.collapseCycles(for: classicalMove.piece, at: classicalMove.position)
            gameModel.lastPieces = nil
            
        default:
            fatalError()
        }
        
        if gameModel.isUserBoard {
            gameModel.beginNextRound()
        } else {
            gameModel.count += 1
        }
        
    }
    
    
    public func setGameModel(_ gameModel: GKGameModel) {
        guard let model = gameModel as? ModelClass else { fatalError() }
        
        self.gameModel.count = model.gameModel.count
        self.gameModel.gameBoard = model.gameModel.gameBoard
        self.gameModel.lastPieces = model.gameModel.lastPieces
        self.players = model.players
    }
    
//    public func isWinForPlayer(player: GKGameModelPlayer) -> Bool {
//        guard let p = player as? PlayerClass, case let .Win(player, _, _) = gameModel.userHasWon() else { return false }
//        return player == p.player
//    }
//    
//    public func isLossForPlayer(player: GKGameModelPlayer) -> Bool {
//        guard let op = players?[player.playerId+1 % 1] else { fatalError() }
//        return isWinForPlayer(op)
//    }
    
    public func copy(with zone: NSZone?) -> Any {
        return type(of: self).init(self)
    }
}








