import random

class Minesweeper:
    def __init__(self, rows, cols, num_mines):
        self.rows = rows
        self.cols = cols
        self.num_mines = num_mines
        self.board = [['*' for _ in range(cols)] for _ in range(rows)]
        self.hidden_board = [['*' for _ in range(cols)] for _ in range(rows)]
        self.mines = self.generate_mines()
        self.game_over = False
        self.num_revealed = 0
        self.flags = set()  # Track placed flags

    def generate_mines(self):
        mines = set()
        while len(mines) < self.num_mines:
            row = random.randint(0, self.rows - 1)
            col = random.randint(0, self.cols - 1)
            mines.add((row, col))
        return mines

    def get_adjacent_cells(self, row, col):
        adjacent_cells = []
        for i in range(max(0, row - 1), min(row + 2, self.rows)):
            for j in range(max(0, col - 1), min(col + 2, self.cols)):
                if (i, j) != (row, col):
                    adjacent_cells.append((i, j))
        return adjacent_cells

    def count_adjacent_mines(self, row, col):
        count = 0
        for i, j in self.get_adjacent_cells(row, col):
            if (i, j) in self.mines:
                count += 1
        return count

    def reveal_cell(self, row, col):
        if self.game_over:
            return

        if (row, col) in self.mines:
            self.game_over = True
            self.board[row][col] = 'M'
            print("Game Over! You hit a mine.")
            self.print_board()
            return

        if self.board[row][col] != '*':
            return

        self.num_revealed += 1
        self.board[row][col] = str(self.count_adjacent_mines(row, col))

        if self.count_adjacent_mines(row, col) == 0:
            for i, j in self.get_adjacent_cells(row, col):
                self.reveal_cell(i, j)

    def place_flag(self, row, col):
        if self.game_over:
            return

        if (row, col) in self.flags:
            self.flags.remove((row, col))
            self.board[row][col] = '*'
        else:
            self.flags.add((row, col))
            self.board[row][col] = 'F'

    def print_board(self):
        print("   ", end="")
        for col in range(self.cols):
            print(f"{col:2d} ", end="")
        print()
        for row in range(self.rows):
            print(f"{row:2d} ", end="")
            for col in range(self.cols):
                print(f"{self.board[row][col]:2s} ", end="")
            print()

    def play(self):
        while not self.game_over:
            self.print_board()
            while True:
                action = input("Enter action (r/f/q): ").lower()
                if action not in ('r', 'f', 'q'):
                    print("Invalid action. Please enter 'r' to reveal, 'f' to flag, or 'q' to quit.")
                    continue

                if action == 'q':
                    print("Exiting game.")
                    return

                try:
                    row = int(input("Enter row: "))
                    col = int(input("Enter column: "))
                    if 0 <= row < self.rows and 0 <= col < self.cols:
                        break
                    else:
                        print("Invalid row or column. Please enter valid coordinates.")
                except ValueError:
                    print("Invalid input. Please enter numbers.")

            if action == 'r':
                self.reveal_cell(row, col)
            elif action == 'f':
                self.place_flag(row, col)

            if self.num_revealed == self.rows * self.cols - self.num_mines:
                self.game_over = True
                print("You Win!")
                self.print_board()

if __name__ == '__main__':
    while True:
        try:
            rows = int(input("Enter number of rows: "))
            cols = int(input("Enter number of columns: "))
            num_mines = int(input("Enter number of mines: "))
            if rows * cols > num_mines:
                break
            else:
                print("Number of mines cannot exceed the number of cells. Please try again.")
        except ValueError:
            print("Invalid input. Please enter numbers.")
    game = Minesweeper(rows, cols, num_mines)
    game.play()
