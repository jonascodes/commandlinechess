require 'colorize'

class Field
    attr_accessor :piece
    attr_reader :color

    def initialize(color)
        @color = color #1 for white, (-1) for black 
        @piece = nil
    end
end
class Chessgame

    def get_default_piece(x,y)
        y == 1 || y == 2 ? (color = 1) : (color = -1) #white is below
        if y == 2 || y == 7
            piece = Pawn.new(x,y,color)
        elsif y == 1 || y == 8
            if x == 1 || x == 8
                piece = Rook.new(x,y,color)
            elsif x == 2 || x == 7
                piece = Knight.new(x,y,color)
            elsif x == 3 || x == 6
                piece = Bishop.new(x,y,color)
            elsif x == 4
                piece = King.new(x,y,color)
            elsif x == 5
                piece = Queen.new(x,y,color)
            end
        else
            return nil
        end
    end

    #takes a color, and start position and a target position and makes a move
    #requires pre-validation of valid moves.
    def make_move!(board, color, start, target)

        start_piece = board[start].piece

        #if move is a castling
        if start_piece.name == "King" && ((color == 1 && start_piece.position == [4,1] && (target == [2,1] || target == [6,1])) || (color == -1 && start_piece.position == [4,8] && (target == [2,8] || target == [6,8])))

            king = board[start].piece
            rook_start = [1,1] if target == [2,1]
            rook_start = [8,1] if target == [6,1]
            rook_start = [1,8] if target == [2,8]
            rook_start = [8,8] if target == [6,8]
            rook_target = [3,1] if target == [2,1]
            rook_target = [5,1] if target == [6,1]
            rook_target = [3,8] if target == [2,8]
            rook_target = [5,8] if target == [6,8]
            rook = board[rook_start].piece if target == [2,1]
            rook = board[rook_start].piece if target == [6,1]
            rook = board[rook_start].piece if target == [2,8]
            rook = board[rook_start].piece if target == [6,8]
            #step1: update king's target field
            board[target].piece = king

            #step 2: update the king's postion to the target field & increase move counter
            board[target].piece.position = target
            board[target].piece.moves += 1

            #step 3: remove the king from the start field
            board[start].piece = nil

            #step 4: update rooks's target field
            board[rook_target].piece = rook

            #step 5: update the rook's postion to the target field & increase move counter
            board[rook_target].piece.position = rook_target
            board[rook_target].piece.moves += 1

            #step 3: remove the rook from the start field
            board[rook_start].piece = nil

        else
            #step 1: update the target field to contain the piece
            board[target].piece = board[start].piece

            #step 2: update the pieces's postion to the target field & increase move counter
            board[target].piece.position = target
            board[target].piece.moves += 1

            #step 2: remove the piece from the start field
            board[start].piece = nil
        end


        return true
    end

    def deep_copy(o)
        Marshal.load(Marshal.dump(o))
    end

    attr_reader :board
    def initialize()
        @turns = 1
        @board = Hash.new()
        for x in 1..8
            for y in 1..8
                (x+y) % 2 == 0 ? ( color = 1 ) : ( color = -1 ) #1 for white, (-1) for black 
                field = Field.new(color)
                field.piece = get_default_piece(x,y)    
                @board[[x,y]] = field
            end
        end
    end

    def color_name(color)
        if color == 1
            return "White"
        else
            return "Black"
        end
    end

    def draw_board!(board, checkmate)
        system ("clear")
        in_check = in_check(board) # will show if a player is putting check on the other
        puts ""
        puts "CommandLine Chess v0.1 by Jonas - Turn #0"
        puts ""
        for y in 1..8
            print " #{9-y} "
            for x in 1..8
                #board coordinates are cartesian, but output is by line, starting with line 8 
                field = board[[x,9-y]]
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
                
                if x == 8 && y == 8 && in_check != 0 && !checkmate
                    print "  #{color_name(in_check)} is in check!".red
                end
            end
            print "\n"
        end
        puts "    A  B  C  D  E  F  G  H "
        puts @error_message.to_s.red
    end

    #returns true if there is no piece on the field
    def field_empty?(field)
        if field.piece == nil
            return true
        else
            return false
        end
    end

    #checks if a potential target field of a move is still on the board
    def out_of_board?(target_field)
        target_field[0] < 1 || target_field[1] <1 || target_field[0] > 8 || target_field[1] > 8 ? (return true) : (return false)
    end

    #checks if the given piece can walk from start to target
    def legal_move_target(piece, start, target)
        walk = piece.walk
        if piece.name == "Pawn" 
            #white pawn on row 2 or black pawn on row 7
            if (piece.color == 1 && start[1] == 2) || (piece.color == -1 && start[1] == 7)
                walk = piece.walk_first
            end
        end
        walk.each do |w|
            if start[0] + w[0] == target[0] && start[1] + w[1] == target[1]
                return true
            end
        end
        return false
    end

    #checks if the given piece can walk from start to target
    def legal_hit_target(piece, start, target)
        hit = piece.hit
        hit.each do |h|
            if start[0] + h[0] == target[0] && start[1] + h[1] == target[1]
                return true
            end
        end
        return false
    end

    #checks if user field input is valid: must be in [a-h][1-8]
    def valid_syntax?(input)
        if input.length != 2 || input.to_s.downcase.match(/[a-h][1-8]/) == nil
            return false
        else
            return true
        end
    end

    #translates user field-input (e.g c5) data field [5,3]
    #function execpts 2-digit sting, first char [a-h], second char [1-8]
    def translate_to_coordinate(input)
        x = input[0].ord - 96 #ord returns 97 for a, 98 for b, etc.
        y = input[1].to_i
        return [x,y]
    end

    #translates data field [5,3] tp user field-input (e.g c5) 
    def translate_to_user_input(tupel)
        a = (tupel[0]+96).chr 
        b = tupel[1].to_s
        return a + b
    end

    #returns the color of the piece on the field. Zero of no piece
    def piece_color_on_field(field)
        if field.piece == nil
            return 0
        else
            return field.piece.color
        end
    end

    #checks if any field between start and target is occupied by a piece
    def path_blocked?(board, start, target)
        blocked = false
        sx = start[0]
        sy = start[1]
        tx = target[0]
        ty = target[1]
        if (tx - sx) == 0 
            x_inc = 0
        else
            if (tx - sx) > 0
                x_inc = 1
            else
                x_inc = -1
            end
        end
        if (ty - sy) == 0 
            y_inc = 0
        else
            if (ty - sy) > 0
                y_inc = 1
            else
                y_inc = -1
            end
        end

        while ((sx + x_inc) != tx) || ((sy + y_inc) != ty)
            piece = board[[sx + x_inc, sy + y_inc]].piece
            #print "checking [#{sx + x_inc}, #{sy + y_inc}]..."
            if piece != nil
                blocked = true
                #puts "occupied!"
            else
                #puts "free!"
            end
            sx = sx + x_inc
            sy = sy + y_inc
        end
        
        return blocked
    end

    #returns all pieces of the board of the given color
    def all_pieces(board, check_color)
        pieces = []
        for x in 1..8
            for y in 1..8
                field = board[[x,y]]
                if field.piece != nil
                    if field.piece.color == check_color
                        pieces.push(field.piece)
                    end
                end
            end
        end
        return pieces
    end

    #adds the coordinates of two positions
    def add_positions(p1,p2)
        return [p1[0]+p2[0], p1[1]+p2[1]]
    end

    #returns all possible moves for a piece
    def all_moves(piece)
        moves = []
        moves = piece.walk + piece.hit
        if piece.name == "Pawn"
            moves = moves + piece.walk_first
        end
        return moves.uniq!
    end

    #returns the color of the player that is checkmate. Zero if none is checkmate
    def checkmate(board)
        check_color = in_check(board)
        if check_color == 0
            return 0
        else
            #check every move if it would result in a non-check situation
            #if none can be found, its checkmate!
            checkmate = check_color
            pieces = all_pieces(board, check_color)
            pieces.each do |piece|
                moves = all_moves(piece) #contains walks and hits
                #check if a walk or a hit would uncheck the king
                piece.walk.each do |move|
                    target = add_positions(piece.position,move)
                    if !out_of_board?(target)
                        if valid_move?(board, check_color, piece.position, target)
                            new_board = deep_copy(board)
                            make_move!(new_board,check_color,piece.position,target)
                            if in_check(new_board) != check_color
                                checkmate = 0
                            end
                        end
                    end
                end
            end
        end
        return checkmate
    end

    #returns true if the move is an attempt to perform a castling
    def move_is_castling?(start_piece, target, color)
        return start_piece.name == "King" && ((color == 1 && start_piece.position == [4,1] && (target == [2,1] || target == [6,1])) || (color == -1 && start_piece.position == [4,8] && (target == [2,8] || target == [6,8])))        
    end

    #check if an attempted castling meets all requirements
    def castling_conditions_met?(board, start_piece, target, color)
        
        #Conditions that castling is permitted
        #1. King may not have moved yet
        if start_piece.moves > 0
            @error_message =  "Invalid move! Castling not allowed, the King has already moved."
            return false
        end

        #2. Involved Rook may not have moved yet, too.
        castling_rook = board[[1,1]].piece if target == [2,1]
        castling_rook = board[[1,8]].piece if target == [6,1]
        castling_rook = board[[8,1]].piece if target == [2,8]
        castling_rook = board[[8,8]].piece if target == [6,8]
        if castling_rook == nil
            @error_message =  "Invalid move! Castling not allowed, the Rook has already moved."
            return false
        else
            if castling_rook.moves > 0
                @error_message =  "Invalid move! Castling not allowed, the Rook has already moved."
                return false  
            end
        end

        #3. King may not be in check
        if in_check(board) == color
            @error_message =  "Invalid move! Castling not allowed, King is in check."
            return false                  
        end

        #3. The fields between king and rook may be under threat
        involved_fields = [[2,1],[3,1]] if target == [2,1]
        involved_fields = [[5,1],[6,1],[7,1]] if target == [6,1]
        involved_fields = [[2,8],[3,8],] if target == [2,8]
        involved_fields = [[5,8],[6,8],[7,8]] if target == [6,8]

        if fields_under_threat_of_capture(board, color*(-1)).include?(involved_fields)
            @error_message =  "Invalid move! Castling not allowed, fields between King and Rook are under attack."
            return false  
        end

        #4. All fields between king and rook must be empty
        involved_fields.each do |f|
            field = board[f]
            if !field_empty?(field)
                @error_message =  "Invalid move! Castling not allowed, fields between King and Rook not empty."
                return false                      
            end
        end

        #if none of the above checks cause a "return false", return true
        return true

    end

    #checks if the tartget field is allowed. Sets error message if not
    def valid_move?(board, color, start, target)
        
        #get the piece of the start field
        start_field = board[start]
        start_piece = start_field.piece

        #get the target field for user_input
        target_field = board[target]
        target_piece = target_field.piece

        #target_field cannot have a piece of the player's color
        if piece_color_on_field(target_field) == color
            @error_message = "There is alredy one of your pieces on #{translate_to_user_input(target)}. Please choose a valid move."
            return false
        end

        #check if all fields between start and target are free
        #this procedure will crash for invalid moves, like [1,1]->[2,4] (impossible walk). Test validity of move first
        legal_move = legal_move_target(start_piece, start, target)
        legal_hit = legal_hit_target(start_piece, start, target)

        if legal_move || legal_hit
            
            #move is allowed, but path may not be blocked (except for Knight)
            if !start_piece.jumps
                if path_blocked?(board, start, target)
                    @error_message =  "Invalid move! The path from #{translate_to_user_input(start)} to #{translate_to_user_input(target)} is blocked."
                    return false
                end
            end

        else
            #not a legal (regular) move for the piece. Could be a special move like castling or en-passant
            castling = move_is_castling?(start_piece, target, color)
            if castling
                if !castling_conditions_met?(board, start_piece, target, color)
                    return false
                end
            end

            #TO BE IMPLEMENTED
            # if move_is_en_passant?(start_piece, target, color)
            #     en_passant = en_passent_conditions_met?(board, start_piece, target, color)
            # end
            en_passant = false
            
            #not a castling, and neither move or hit are legal moves - define the error message
            if !castling && !en_passant
                #check if the target field is empty, or if move would be a hit

                if !field_empty?(target_field)
                    #special case for pawns: pawns walk forward but hit left-forward or right-forward 
                    @error_message = "Invalid move! A #{start_piece.name} cannot hit that way! Please choose a valid move"
                    return false
  
                else
                    @error_message =  "Invalid move! A #{start_piece.name} cannot walk that way! Please choose a valid move."
                    return false
                end

            end
        end

        #check if the king is in check. If so, the move MUST uncheck the king
        if in_check(board) == color
            new_board = deep_copy(board)
            make_move!(new_board,color,start,target)
            if in_check(new_board) == color 
                @error_message =  "Invalid move! Your king is still in check!"
                return false
            end
        end

        return true
    end

    #checks if the start field is allowed. Also puts error message if not
    def valid_start_field?(board, color, input)        

        #get the start field for user_input
        start_field = board[input]
        
        #field has to contain a piece of the player's color
        if piece_color_on_field(start_field) != color
            @error_message = "There is no piece of your's on " + translate_to_user_input(input).to_s + ". Please choose a valid field."
            return false
        end
        
        return true
    end

    #returns the field coordinates of the king
    def get_king_field(board, color)
        for x in 1..8
            for y in 1..8
                position = [x,y]
                field = board[position]
                if field.piece != nil
                    if field.piece.color == color && field.piece.name == "King"
                        return position
                    end
                end
            end
        end    
    end

    #checks if the king's field is under attack by the oponent
    def in_check(board)
        king_position = get_king_field(board, 1)
        check = fields_under_threat_of_capture(board, -1).include?(king_position)
        if check 
            return 1
        else
            king_position = get_king_field(board, -1)
            check = fields_under_threat_of_capture(board, 1).include?(king_position)
            if check 
                return -1
            else
                return 0
            end
        end
    end

    #returns all fields threatened by a piece from a given position
    def threatened_fields(piece, position)
        threatened_fields = []
        hit = piece.hit
        hit.each do |h|
            target = [position[0] + h[0], position[1] + h[1]]
            if !out_of_board?(target)
                #only if piece does not jump: check if path to threatened field is not blocked
                if !piece.jumps
                    if !path_blocked?(board, position, target)
                        threatened_fields.push(target)
                    end
                else
                    threatened_fields.push(target)
                end
            end
        end
        return threatened_fields
    end

    #returns all fields that are currently under threat by the given color
    def fields_under_threat_of_capture(board, color)
        fields_under_threat = []
        for x in 1..8
            for y in 1..8
                position = [x,y]
                piece = board[position].piece
                if piece != nil
                    if piece.color == color
                        fields_under_threat = fields_under_threat + threatened_fields(piece, position)
                    end
                end
            end
        end
        return fields_under_threat.uniq!
    end


    def new_game!(color)
 
        while checkmate(board) == 0
            @error_message = nil
            valid_start = false
            valid_target = false
            #puts fields_under_threat_of_capture(@board, 1).inspect
            #exit

            while !valid_start || !valid_target
                draw_board!(@board, false)
                puts "#{color_name(color)}".bold + ", which piece do you want to move? (Enter field ID like 'e5')"
                print "> "
                input_start = gets.chomp
                if valid_syntax?(input_start)
                    start = translate_to_coordinate(input_start)
                    valid_start = valid_start_field?(@board, color, start)
                end
                if valid_start
                    @error_message = nil
                    draw_board!(@board, false)
                    puts "#{color_name(color)}".bold + ", where should the " + "#{@board[start].piece.name}".bold + " move to from " + "#{input_start}".bold + "?"
                    print "> "
                    input_target = gets.chomp
                    if valid_syntax?(input_target)
                        target = translate_to_coordinate(input_target)
                        valid_target = valid_move?(@board, color, start, target)
                    end
                end
            end
            target = translate_to_coordinate(input_target)
            puts "Valid move: #{input_start} -> #{input_target}".green

            make_move!(@board, color, start, target)
            @turns += 1
            color = color * (-1)
        end
        @error_message = ""
        draw_board!(@board, true)
        puts "#{color_name(color)} is checkmate!".bold + " " + "#{color_name(color * (-1))}".bold + " wins in #{@turns/2.to_i} turns!"

    end

end

class ChessPiece
    attr_accessor :position
    attr_reader :symbol
    attr_reader :color
    attr_reader :name
    attr_reader :walk
    attr_reader :walk_first
    attr_reader :hit
    attr_reader :jumps
    attr_accessor :moves

    def initialize(column, row, color)
        @position = [column, row]
        @color = color #1 for white, (-1) for black
        @symbol = " " 
        @jumps = false
        @moves = 0
    end
end

class Pawn < ChessPiece
    def initialize(column, row, color)
        @position = [column, row]
        @walk = [[0,1*color]]
        @walk_first = [[0,1*color], [0,2*color]]
        @hit = [[-1,1*color], [1,1*color]]
        @color = color
        @jumps = false
        @moves = 0
        if color == 1
            @symbol = "♙"
        else
            @symbol = "♟"
        end
        @name = "Pawn"
    end
end

class King < ChessPiece
    def initialize(column, row, color)
        @position = [column, row]
        @walk = [[-1,1], [-1,0], [-1,-1], [0,1], [0,-1], [1,1], [1,0], [1,-1]] 
        @hit = [[-1,1*color],[1,1*color]]
        @color = color
        @jumps = false
        @moves = 0
        if color == 1
            @symbol = "♔"
        else
            @symbol = "♚"
        end
        @name = "King"
    end
end

class Knight < ChessPiece
    def initialize(column, row, color)
        @position = [column, row]
        @walk = [[1,2], [2,1], [-1,2], [-2,1], [1,-2], [2,-1], [-1,-2], [-2,-1]]
        @hit = @walk
        @color = color
        @color = color
        @jumps = true
        @moves = 0
        if color == 1
            @symbol = "♘"
        else
            @symbol = "♞"
        end
        @name = "Knight"
    end
end

class Bishop < ChessPiece
    def initialize(column, row, color)
        @position = [column, row]
        @walk = [[1,1], [2,2], [3,3], [4,4], [5,5], [6,6], [7,7]]
        @walk = @walk + [[-1,-1], [-2,-2], [-3,-3], [-4,-4], [-5,-5], [-6,-6], [-7,-7]]
        @walk = @walk + [[-1,1], [-2,2], [-3,3], [-4,4], [-5,5], [-6,6], [-7,7]]
        @walk = @walk + [[1,-1], [2,-2], [3,-3], [4,-4], [5,-5], [6,-6], [7,-7]]
        @hit = @walk
        @color = color
        @jumps = false
        @x = column
        @y = row
        @moves = 0
        if color == 1
            @symbol = "♗"
        else
            @symbol = "♝"
        end
        @name = "Bishop"
    end
end

class Queen < ChessPiece
    def initialize(column, row, color)
        @position = [column, row]
        @walk = [[1,1], [2,2], [3,3], [4,4], [5,5], [6,6], [7,7]]
        @walk = @walk + [[-1,-1], [-2,-2], [-3,-3], [-4,-4], [-5,-5], [-6,-6], [-7,-7]]
        @walk = @walk + [[-1,1], [-2,2], [-3,3], [-4,4], [-5,5], [-6,6], [-7,7]]
        @walk = @walk + [[1,-1], [2,-2], [3,-3], [4,-4], [5,-5], [6,-6], [7,-7]]
        @walk = @walk + [[0,1], [0,2], [0,3], [0,4], [0,5], [0,6], [0,7]]
        @walk = @walk + [[0,-1], [0,-2], [0,-3], [0,-4], [0,-5], [0,-6], [0,-7]]
        @walk = @walk + [[1,0], [2,0], [3,0], [4,0], [5,0], [6,0], [7,0]]
        @walk = @walk + [[-1,0], [-2,0], [-3,0], [-4,0], [-5,0], [-6,0], [-7,0]]
        @hit = @walk
        @jumps = false
        @color = color
        @moves = 0
        if color == 1
            @symbol = "♕"
        else
            @symbol = "♛"
        end
        @name = "Queen"
    end
end

class Rook < ChessPiece
    def initialize(column, row, color)
        @position = [column, row]
        @walk = [[0,1], [0,2], [0,3], [0,4], [0,5], [0,6], [0,7]]
        @walk = @walk + [[0,-1], [0,-2], [0,-3], [0,-4], [0,-5], [0,-6], [0,-7]]
        @walk = @walk + [[1,0], [2,0], [3,0], [4,0], [5,0], [6,0], [7,0]]
        @walk = @walk + [[-1,0], [-2,0], [-3,0], [-4,0], [-5,0], [-6,0], [-7,0]]
        @hit = @walk
        @jumps = false
        @color = color
        @moves = 0
        if color == 1
            @symbol = "♖"
        else
            @symbol = "♜"
        end
        @name = "Rook"
    end
end

c = Chessgame.new()
# c.make_move!(c.board,-1,[4,7],[4,6])
# c.make_move!(c.board,-1,[2,8],[3,6])
# c.make_move!(c.board,1,[3,8],[5,6])
#c.make_move!(c.board,1,[4,8],[2,8])

# c.make_move!(c.board,1,[2,1],[1,3])
# c.make_move!(c.board,1,[4,1],[2,1])
# c.path_blocked?(c.board, [4,1], [3,2])
 c.new_game!(1)


# c.make_move!(c.board,-1,[7,8],[6,6])
# c.make_move!(c.board,-1,[6,6],[4,5])
# c.make_move!(c.board,-1,[4,5],[6,4])
# c.make_move!(c.board,-1,[6,4],[4,3])
# c.draw_board!(c.board)

# c.make_move!(c.board,1,[3,3],[5,4])
# c.draw_board!(c.board)
# c.make_move!(c.board,1,[5,4],[3,6])
# c.draw_board!(c.board)
# c.make_move!(c.board,-1,[2,8],[1,6])
# c.draw_board!(c.board)


##c.make_move!(c.board,1,[2,1],[3,3])
#c.draw_board!(c.board)
#puts c.fields_under_threat_of_capture(c.board, 1).inspect
#puts c.get_king_field(c.board, 1).inspect
#puts c.get_king_field(c.board, -1).inspect

#to-dos
# - Check that path is free for move of piece that doesnt jump - OK
# - Check if a field is under attack - OK
# - check if the king is in check - OK
# - in case the king is in check, the next move must uncheck him - OK
# - check for CHECKMATE - OK
# - Special Move: Rochade / Castling left/right - OK
# - Special Move: En Passant 
# - Add a colored version of a piece to the board after selecting a piece for a move to indicate possible moves...?
# - bugfix: no error message if first input is invalid
# - bufgix: black rochade (short) moved white rook up