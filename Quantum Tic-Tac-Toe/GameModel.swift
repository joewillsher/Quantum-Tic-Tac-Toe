//
//  GameModel.swift
//  Quantum Tic-Tac-Toe
//
//  Created by Josef Willsher on 31/07/2015.
//  Copyright © 2015 Josef Willsher. All rights reserved.
//

public enum Diag {
    case tl, tr
}

public enum BoardStrip {
    case row(Int), column(Int), diagonal(Diag)
}

public enum WinResult {
    case win(Player, BoardStrip, Int)
    case noWin
    indirect case wins([WinResult])
    
    
    public func winType() -> WinType {
        
        switch self {
        case .noWin:
            return .draw
            
        case let .win(player, _, _):
            return .win(player)
            
        case let .wins(wins):
            
            let xs = wins.filter { win in
                guard case let .win(player, _, _) = win else { return false }
                return player == .x
            }
            let os = wins.filter { win in
                guard case let .win(player, _, _) = win else { return false }
                return player == .o
            }
            
            switch (xs.count, os.count) {
            case let (n, 0) where n > 1: return .doubleWin(.x)
            case let (0, n) where n > 1: return .doubleWin(.o)
            case let (n, 1) where n > 1: return .narrowWin(.x)
            case let (1, n) where n > 1: return .narrowWin(.o)
            case let (a, b) where a == b:
                
                var min = Int.max
                var minPlayer: Player?
                
                for win in wins {
                    if case let .win(p, _, n) = win, n < min {
                        min = n
                        minPlayer = p
                    }
                }
                
                if let p = minPlayer { return .narrowWin(p) }
                else { fallthrough }
                
            default:
                return .draw
            }
            
        }
    }
}
public enum WinType {
    case win(Player)
    case doubleWin(Player)
    case narrowWin(Player)
    case draw
}



public protocol GameModelProtocol : class {
    
    func requestSelection(between t: (BoardPosition, BoardPosition), player: Player, completion: @escaping (BoardPosition) -> Void)
    func addQuantumPieces(for player: QuantumPlayer, completion: @escaping (BoardPosition, BoardPosition) -> Void)
    
    func makeTile(at position: BoardPosition, classicalPlayer player: Player)
    func requestSelection(between: (BoardPosition, BoardPosition))
    
    func presentWin(for win: WinType)
    func drawWin(at loc: BoardStrip)
}

public class GameModel {
    
    public var delegate: GameModelProtocol?
    public var gameBoard: GameBoard
    public var isUserBoard: Bool { return delegate != nil }
    
    internal var count: Int
    public var player: Player {
        return count % 2 == 0 ? .o : .x
    }
    public var lastPieces: (QuantumPlayer, QuantumPlayer)?
    
    public init() {
        count = 0
        gameBoard = GameBoard()
    }
    
    /// Begin turn, updates VC
    public func beginTurn() {
        
        if let (p, _) = lastPieces, cyclesPresent(for: p) {

            let _locs = gameBoard.locations(of: p), locs = (_locs[0], _locs[1])
            
            delegate?.requestSelection(between: locs) // get UI to request
            delegate?.requestSelection(between: locs, player: player) { selected in // update model, pass in callback
                self.lastPieces = nil
                self.collapseCycles(for: p, at: selected)
                self.beginNextRound()
            }
            
        } else {
            delegate?.addQuantumPieces(for: (player, count)) { p in //
                self.playMoves(at: (p.0, p.1))
                self.beginNextRound()
            }
        }
    }
    
    /// Adds quantum pieces
    internal func playMoves(at pos: (BoardPosition, BoardPosition)) {
        lastPieces = (add(quantumPiece: player, at: pos.0), add(quantumPiece: player, at: pos.1))
    }
    
    //helper function
    internal func add(quantumPiece piece: Player, at pos: BoardPosition) -> QuantumPlayer {

        if case let .quantum(arr) = gameBoard[pos] {
            gameBoard[pos] = .quantum(arr + [(piece, count)])
        } else {
            gameBoard[pos] = .quantum([(piece, count)])
        }
        
        return (piece, count)
    }
    

    /// Returns whether there are cycles for a piece
    public func cyclesPresent(for piece: QuantumPlayer) -> Bool {
        
        guard let loc = gameBoard.locations(of: piece).first else { return false }
        return branch(of: loc, piece: piece, start: loc)
    }
    
    // helper function
    fileprivate func branch(of pos: BoardPosition, piece: QuantumPlayer, start: BoardPosition) -> Bool {
        guard case let .quantum(players) = gameBoard[pos] else { return false }
        
        for player in players where player != piece {
            
            guard let loc = gameBoard.otherLocation(of: player, location: pos) else { continue }
            
            if loc.0 == start.0 && loc.1 == start.1 { return true }
            if branch(of: loc, piece: player, start: start) { return true }
        }
        
        return false
    } 
    
    
    /// Collapses cycles drom a piece and position
    internal func collapseCycles(for piece: QuantumPlayer, at position: BoardPosition) {
        
        guard case let .quantum(branches) = gameBoard[position] else { return }
        gameBoard[position] = .classical(player: piece.player, num: piece.num) // Collapse node
        delegate?.makeTile(at: position, classicalPlayer: piece.player) // update UI
        
        for branch in branches where branch != piece { // Iterate over each branch (apart from the one going backwards)
            
            // if the corresponding piece is found and it is a quantum piece, collapse it
            if let branchPos = gameBoard.otherLocation(of: branch, location: position), case .quantum = gameBoard[branchPos] {
                
                collapseCycles(for: branch, at: branchPos)
            }
        }
    }
    
    
    /// Begin the next turn, checking whether a user has won or whether one can
    internal func beginNextRound() {
        count += 1
        
        let result = userHasWon()
        switch result {
        case let .win(_, loc, _):
            delegate?.drawWin(at: loc)
            
        case let .wins(wins):
            var players = [Player]()
            
            for win in wins {
                if case let .win(player, loc, _) = win {
                    delegate?.drawWin(at: loc)
                    players.append(player)
                }
            }
            
        case .noWin where cannotWin():
            break
            
        case .noWin:
            beginTurn()
            return
        }
        
        delegate?.presentWin(for: result.winType())
        
    }
    
    
    /// Returns whether a user has won
    public func userHasWon() -> WinResult {
        var res = [WinResult]()
        
        for (i, row) in gameBoard.rows().enumerated() {
            if case let a = row.getClassical(), let player = a.allElementsEqual(), let max = row.getIndicies().max(), a.count == 3 { res.append(.win(player, .row(i), max)) }
        }
        
        for (i, col) in gameBoard.columns().enumerated() {
            if case let a = col.getClassical(), let player = a.allElementsEqual(), let max = col.getIndicies().max(), a.count == 3 { res.append(.win(player, .column(i), max)) }
        }
        
        for (i, diag) in gameBoard.diagonals().enumerated() {
            if case let a = diag.getClassical(), let player = a.allElementsEqual(), let max = diag.getIndicies().max(), a.count == 3 { res.append(.win(player, .diagonal(i == 0 ? .tl : .tr), max)) }
        }
        
        switch res.count {
        case 0: return .noWin
        case 1: return res[0]
        case _: return .wins(res)
        }
    }
    
    /// Returns whether it is impossible to win
    open func cannotWin() -> Bool {
        
        func isClassical(_ t: Tile) -> Bool { if case .classical = t { return false } else { return true } }
        
        if gameBoard.boardArray.filter(isClassical).count <= 1 { return true }
        
        let noWinningMoves = gameBoard.slices()
            .map(getClassical)
            .filter(isEmpty || allElementsAreEqual)

        if noWinningMoves.count <= 1 { return true }
        
        return false
    }
    
}




