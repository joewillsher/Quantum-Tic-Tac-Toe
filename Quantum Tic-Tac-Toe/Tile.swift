//
//  Tile.swift
//  Quantum Tic-Tac-Toe
//
//  Created by Josef Willsher on 31/07/2015.
//  Copyright © 2015 Josef Willsher. All rights reserved.
//


public enum Player {
    case o, x
    
    func other() -> Player {
        return self == .x ? .o : .x
    }
    
    public var index: Int {
        return self == .o ? 0 : 1
    }
}

extension Player: Hashable {
    public var hashValue: Int {
        return index
    }
}

extension Player: Equatable {}

public typealias QuantumPlayer = (player: Player, num: Int)
public typealias ClassicalPlayer = QuantumPlayer

public func == (p0: QuantumPlayer, p1: QuantumPlayer) -> Bool {
    return p0.0 == p1.0 && p0.1 == p1.1
}
public func != (p0: QuantumPlayer, p1: QuantumPlayer) -> Bool {
    return !(p0 == p1)
}




public enum Tile {
    case empty
    case classical(ClassicalPlayer)
    case quantum([QuantumPlayer])
}

public func == (lhs: Tile, rhs: Tile) -> Bool {
    switch (lhs, rhs) {
    case (.empty, .empty): return true
    case let (.classical(a), .classical(b)): return a.player == b.player
    case let (.quantum(a), .quantum(b)): return a.elementsEqual(b, by: {$0 == $1})
    default: return false
    }
}
extension Tile: Equatable {}


public typealias BoardPosition = (Int, Int)

public func areEqual(_ p1: BoardPosition, _ p2: BoardPosition) -> Bool {
    return p1.0 == p2.0 && p1.1 == p2.1
}

public extension Collection where Iterator.Element: Equatable {
    
    /// If all elements are equal it returns that value, otherwise nil
    func allElementsEqual() -> Iterator.Element? {
        
        guard let f = self.first else { return nil }
        for element in self where element != f { return nil }
        return f
    }
    
}

public extension Collection where Iterator.Element == Tile {
    func getClassical() -> [Player] {
        return flatMap { if case let .classical(p) = $0 { return p.player } else { return nil }}
    }
    
    func getIndicies() -> [Int] {
        return flatMap { if case let .classical(p) = $0 { return p.num } else { return nil }}
    }
}

func getClassical(_ t: [Tile]) -> [Player] { return t.getClassical() }
func isEmpty(_ t: [Player]) -> Bool { return t.isEmpty }
func allElementsAreEqual(_ s: [Player]) -> Bool { return s.allElementsEqual() != nil }

func ||<T> (lhs: @escaping (T) -> Bool, rhs: @escaping (T) -> Bool) -> (T) -> Bool {
    return { lhs($0) || rhs($0) }
}



