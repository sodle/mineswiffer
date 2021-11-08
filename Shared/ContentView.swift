//
//  ContentView.swift
//  Shared
//
//  Created by Scott Odle on 11/4/21.
//

import SwiftUI

struct SquareView: View {
    @ObservedObject var square: Square

    @State private var showAlert = false
    @State private var alertType: Alert = Alert(title: Text(""))

    func playHapticSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    let squareSize: CGFloat = 50

    var symbol: String {
        get {
            if square.adjacency == -1 {
                return "💣"
            } else if square.adjacency == 0 {
                return " "
            } else {
                return "\(square.adjacency)"
            }
        }
    }

    func showFlagAlert() {
        alertType = Alert(title: Text("Too many flags!"), message: Text("Remove a flag before placing more."))
        showAlert = true
    }

    func showWinAlert() {
        alertType = Alert(title: Text("You won!"), dismissButton: .default(Text("Play again")) {
            square.board.game.reset()
        })
        showAlert = true
    }

    func showLossAlert() {
        alertType = Alert(title: Text("You lost!"), dismissButton: .default(Text("Play again")) {
            square.board.game.reset()
        })
        showAlert = true
    }

    var body: some View {
        HStack {
            if (square.isRevealed) {
                Text(symbol).foregroundColor(Color.primary)
            } else if (square.isFlagged) {
                Text("🚩")
            }
        }
                .frame(width: squareSize, height: squareSize)
                .background(Rectangle().foregroundColor(square.isRevealed ? Color.clear : Color.gray))
                .border(Color.secondary)
                .onTapGesture {
                    square.reveal()
                    if square.board.isLost {
                        showLossAlert()
                    }
                    if square.board.isWon {
                        showWinAlert()
                    }
                }
                .onLongPressGesture(minimumDuration: 0.2) {
                    if !square.isFlagged && square.board.flagCount >= square.board.mineCount {
                        showFlagAlert()
                        return
                    }
                    playHapticSuccess()
                    square.toggleFlag()
                    if square.board.isWon {
                        showWinAlert()
                    }
                }.alert(isPresented: $showAlert) {
                    alertType
                }
    }
}

struct RowView: View {
    @ObservedObject var row: Row

    var body: some View {
        HStack {
            ForEach(row.squares) { square in
                SquareView(square: square)
            }
        }
    }
}

struct BoardView: View {
    @ObservedObject var board: Board

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack {
                ForEach(board.rows) { row in
                    RowView(row: row)
                }
            }
        }
    }
}

struct ContentView: View {
    @StateObject var game = Game()

    var body: some View {
        if let board = game.board {
            BoardView(board: board)
        } else {
            Text("Generating board...")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
