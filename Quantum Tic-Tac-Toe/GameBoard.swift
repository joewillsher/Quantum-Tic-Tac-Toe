//
//  GameBoard.swift
//  Quantum Tic-Tac-Toe
//
//  Created by Josef Willsher on 31/07/2015.
//  Copyright © 2015 Josef Willsher. All rights reserved.
//

public struct GameBoard {
    
    let d: Int
    public var boardArray: [Tile]
    
    init() {
        d = 3
        boardArray = [Tile](repeating: .empty, count: d*d)
    }
    
    subscript(row: Int, col: Int) -> Tile {
        get {
            return boardArray[col * d + row]
        }
        set {
            boardArray[col * d + row] = newValue
        }
    }
    
    public func locations(of piece: QuantumPlayer) -> [BoardPosition] {
        
        var pieces = [BoardPosition]()
        
        for (i, boardPiece) in boardArray.enumerated() {
            
            if case let .quantum(quantum) = boardPiece {
                for p in quantum where p == piece {
                    pieces.append((i%d, i/d))
                }
            }
        }
        return pieces
    }
    
    func otherLocation(of piece: QuantumPlayer, location loc: BoardPosition) -> BoardPosition? {
        
        let positions = locations(of: piece)
        
        for pos in positions where pos.0 != loc.0 || pos.1 != loc.1 { return pos }
        
        return nil
    }
    
    func rows() -> [[Tile]] {
        
        return (0..<d).map { n in (0..<d).map { self[$0,n] } }
    }
    
    
    func columns() -> [[Tile]] {
        
        return (0..<d).map { n in (0..<3).map { self[n,$0] } }
    }
    
    func diagonals() -> [[Tile]] {
        
        return [
            (0..<d).map { self[$0,$0] },
            (0..<d).map { self[$0,d-$0-1] }
        ]
    }
    
    func slices() -> [[Tile]] {
        return rows() + columns() + diagonals()
    }
    
}


private func desc(_ tile: Tile) -> String {
    switch tile {
    case let .classical(p):
        return p.player == .x ? "X" : "O"
        
    case let .quantum(ps):
        return ps
            .map { "\($0.0)_\($0.1)" }
            .enumerated()
            .reduce("Quantum[") { $0 + $1.1 + ($1.0 == ps.count-1 ? "]" : ", ")}
        
    default: return "__"
    }
}

extension GameBoard: CustomStringConvertible {
    
    public var description: String {
        return boardArray
            .map(desc)
            .enumerated()
            .reduce("") { $0 + ($1.0%3 == 0 ? ",\n" : ",\t\t") + $1.1 }
    }
    
}




