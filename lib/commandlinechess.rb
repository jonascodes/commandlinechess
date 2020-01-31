require 'colorize'

class Field
    attr_accessor :piece
    attr_reader :color

    def initialize(color)
        @color = color #1 for white, (-1) for black 
        @piece = nil
    end
end
class Chessboard

    def get_default_piece(i,j)
        i == 1 || i == 2 ? (color = 1) : (color = -1) #white is below
        if i == 2 || i == 7
            piece = Pawn.new(i,j,color)
        elsif i == 1 || i == 8

            if j == 1 || j == 8
                piece = Rook.new(i,j,color)
            elsif j == 2 || j == 7
                piece = Knight.new(i,j,color)
            elsif j == 3 || j == 6
                piece = Bishop.new(i,j,color)
            elsif j == 4
                if color == 1
                    piece = Queen.new(i,j,color)
                else
                    piece = King.new(i,j,color)
                end
            elsif j == 5
                if color == -1
                    piece = Queen.new(i,j,color)
                else
                    piece = King.new(i,j,color)
                end
            end
        else
            return nil
        end
    end


    attr_reader :board
    def initialize(x=8,y=8)
        @board = Hash.new()
        for i in 1..x
            for j in 1..y
                (i+j) % 2 == 0 ? ( color = (-1) ) : ( color = 1 ) #1 for white, (-1) for black 
                my_field = Field.new(color)
                my_field.piece = get_default_piece(i,j)    
                @board[[i,j]] = my_field
            end
        end
    end
    def draw_board!(board)
        system ("clear")
        puts ""
        puts "CommandLine Chess v0.1 by Jonas - Turn #0"
        puts ""
        for i in 1..8
            print " #{9-i} "
            for j in 1..8
                #board coordinates are cartesian, but output is by line, starting with line 8 
                field = board[[9-i,j]]
                if field.piece == nil
                    show = "   "
                else                
                    show = " " + field.piece.symbol + " "
                end
                if field.color == -1
                    print show.on_white.black
                else
                    print show.on_light_black.black
                end
            end
            print "\n"
        end
        puts "    A  B  C  D  E  F  G  E "
        puts "\nPlayer White, please enter your move. First enter the field id (a6) of the piece you want to move."
        puts "White: field ID > "
    end

    def in_board?(target_field)
        target_field[0] >= 0 && target_field[1]>=0 target_field[0] < 8 && target_field[1] < 8 ? (true) : (false)
    end

end

class ChessPiece
    attr_accessor :position
    attr_reader :symbol
    def initialize(column, row, color)
        @position = [column, row]
        @color = 1 #1 for white, (-1) for black
        @symbol = " " 
    end
end

class Pawn < ChessPiece
    def initialize(column, row, color)
        @walk = [[0,1*color]]
        @hit = [[-1,1*color],[1,1*color]]
        if color == 1
            @symbol = "♙"
        else
            @symbol = "♟"
        end
    end
end

class King < ChessPiece
    def initialize(column, row, color)
        @walk = [[-1,1], [-1,0], [-1,-1], [0,1], [0,-1], [1,1], [1,0], [1,-1]] 
        @hit = [[-1,1*color],[1,1*color]]
        if color == 1
            @symbol = "♔"
        else
            @symbol = "♚"
        end
    end
end

class Knight < ChessPiece
    def initialize(column, row, color)
        @walk = [[1,2], [2,1], [-1,2], [-2,1], [1,-2], [2,-1], [-1,-2], [-2,-1]]
        @hit = @walk
        if color == 1
            @symbol = "♘"
        else
            @symbol = "♞"
        end
    end
end

class Bishop < ChessPiece
    def initialize(column, row, color)
        @walk = [[1,1], [2,2], [3,3], [4,4], [5,5], [6,6], [7,7]]
        @walk = @walk + [[-1,-1], [-2,-2], [-3,-3], [-4,-4], [-5,-5], [-6,-6], [-7,-7]]
        @walk = @walk + [[-1,1], [-2,2], [-3,3], [-4,4], [-5,5], [-6,6], [-7,7]]
        @walk = @walk + [[1,-1], [2,-2], [3,-3], [4,-4], [5,-5], [6,-6], [7,-7]]
        @hit = @walk
        if color == 1
            @symbol = "♗"
        else
            @symbol = "♝"
        end
    end
end

class Queen < ChessPiece
    def initialize(column, row, color)
        @walk = [[1,1], [2,2], [3,3], [4,4], [5,5], [6,6], [7,7]]
        @walk = @walk + [[-1,-1], [-2,-2], [-3,-3], [-4,-4], [-5,-5], [-6,-6], [-7,-7]]
        @walk = @walk + [[-1,1], [-2,2], [-3,3], [-4,4], [-5,5], [-6,6], [-7,7]]
        @walk = @walk + [[1,-1], [2,-2], [3,-3], [4,-4], [5,-5], [6,-6], [7,-7]]
        @walk = @walk + [[0,1], [0,2], [0,3], [0,4], [0,5], [0,6], [0,7]]
        @walk = @walk + [[0,-1], [0,-2], [0,-3], [0,-4], [0,-5], [0,-6], [0,-7]]
        @walk = @walk + [[1,0], [2,0], [3,0], [4,0], [5,0], [6,0], [7,0]]
        @walk = @walk + [[-1,0], [-2,0], [-3,0], [-4,0], [-5,0], [-6,0], [-7,0]]
        @hit = @walk
        if color == 1
            @symbol = "♕"
        else
            @symbol = "♛"
        end
    end
end

class Rook < ChessPiece
    def initialize(column, row, color)
        @walk = [[0,1], [0,2], [0,3], [0,4], [0,5], [0,6], [0,7]]
        @walk = @walk + [[0,-1], [0,-2], [0,-3], [0,-4], [0,-5], [0,-6], [0,-7]]
        @walk = @walk + [[1,0], [2,0], [3,0], [4,0], [5,0], [6,0], [7,0]]
        @walk = @walk + [[-1,0], [-2,0], [-3,0], [-4,0], [-5,0], [-6,0], [-7,0]]
        @hit = @walk
        if color == 1
            @symbol = "♖"
        else
            @symbol = "♜"
        end
    end
end

c = Chessboard.new()
c.draw_board!(c.board) 
