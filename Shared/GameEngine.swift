//
//  GameEngine.swift
//  Minesweeper
//
//  Created by Scott Odle on 11/4/21.
//

import Foundation

struct Coordinate: Hashable, Equatable, CustomStringConvertible {
    let x: Int
    let y: Int
    
    func isAdjacentTo(other: Coordinate) -> Bool {
        if self == other {
            return false
        }
        
        let xRange = x - 1 ... x + 1
        let yRange = y - 1 ... y + 1
        
        return xRange.contains(other.x) && yRange.contains(other.y)
    }

    var description: String {
        get {
            "(x=\(x) y=\(y))"
        }
    }
}

class Square: Identifiable, ObservableObject, CustomStringConvertible {
    let coordinate: Coordinate
    let board: Board
    
    init(x: Int, y: Int, board: Board) {
        coordinate = Coordinate(x: x, y: y)
        self.board = board
    }

    @Published private(set) var isRevealed: Bool = false
    @Published private(set) var isFlagged: Bool = false
    
    var isMine: Bool {
        get {
            board.mines.contains(coordinate)
        }
    }
    
    var neighbors: [Square] {
        get {
            board.squares.filter { square in
                coordinate.isAdjacentTo(other: square.coordinate)
            }
        }
    }
    var adjacency: Int {
        get {
            if isMine {
                // Special value indicating that this is a mine
                return -1
            }
            
            return neighbors.filter { square in
                square.isMine
            }.count
        }
    }
    
    func reveal() {
        if isFlagged {
            // prevent accidentally clicking flagged squares
            return
        }

        if !board.isInitialized {
            board.placeMines(safe: coordinate)
        }

        isRevealed = true
        
        if adjacency == 0 {
            neighbors.forEach { square in
                if !square.isRevealed {
                    square.reveal()
                }
            }
        }
    }

    func toggleFlag() {
        if !isRevealed {
            isFlagged = !isFlagged
        }
    }

    var description: String {
        get {
            "(loc=\(coordinate) adjacency=\(adjacency) revealed=\(isRevealed))"
        }
    }
}

class Row: Identifiable, ObservableObject {
    let squares: [Square]

    init(squares: [Square]) {
        self.squares = squares
    }
}

class Board: ObservableObject {
    let width: Int
    let height: Int
    let mineCount: Int
    let game: Game
    
    var squares: [Square] = []
    var rows: [Row] {
        get {
            (0..<height).map { rowNumber in
                Row(squares: squares.filter { square in
                    square.coordinate.y == rowNumber
                })
            }
        }
    }
    func squareAt(coord: Coordinate) -> Square? {
        squares.first { square in
            square.coordinate == coord
        }
    }

    var mines: Set<Coordinate> = []
    var flags: Set<Coordinate> {
        get {
            Set(squares.filter { square in
                square.isFlagged
            }.map { square in
                square.coordinate
            })
        }
    }
    var flagCount: Int {
        get {
            flags.count
        }
    }

    var unrevealedSquares: Set<Coordinate> {
        get {
            Set(squares.filter { square in
                !square.isRevealed
            }.map { square in
                square.coordinate
            })
        }
    }

    var isWon: Bool {
        get {
            (isInitialized && mines == flags) || mines == unrevealedSquares
        }
    }

    var isLost: Bool {
        get {
            squares.filter { square in
                square.isMine && square.isRevealed
            }.count > 0
        }
    }
    
    init(width: Int, height: Int, mineCount: Int, game: Game) {
        self.width = width
        self.height = height
        self.mineCount = mineCount

        self.game = game
        
        squares = (0..<height).map { y in
            (0..<width).map { x in
                Square(x: x, y: y, board: self)
            }
        }.flatMap { $0 }
    }
    
    var isInitialized: Bool {
        get {
            mines.count == mineCount
        }
    }

    func placeMines(safe: Coordinate?) {
        while mines.count < mineCount {
            let x = Int.random(in: 0..<width)
            let y = Int.random(in: 0..<height)
            let newMine = Coordinate(x: x, y: y)

            if newMine != safe && !mines.contains(newMine) {
                mines.insert(newMine)
            }
        }
    }
}

class Game: ObservableObject {
    @Published var board: Board? = nil

    func reset() {
        board = Board(width: 10, height: 10, mineCount: 10, game: self)
    }

    init() {
        reset()
    }
}
