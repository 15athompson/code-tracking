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
            row = int(input("Enter row: "))
            col = int(input("Enter column: "))
            self.reveal_cell(row, col)

            if self.num_revealed == self.rows * self.cols - self.num_mines:
                self.game_over = True
                print("You Win!")
                self.print_board()

if __name__ == '__main__':
    rows = int(input("Enter number of rows: "))
    cols = int(input("Enter number of columns: "))
    num_mines = int(input("Enter number of mines: "))
    game = Minesweeper(rows, cols, num_mines)
    game.play()
