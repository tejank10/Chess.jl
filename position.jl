# position.jl

# handle adding sliding moves of QUEEN, ROOK, BISHOP
#  which end by being BLOCKED or capturing an enemy piece
UNBLOCKED, BLOCKED = 0,1
function add_move!(moves, b::Board, my_color::UInt8, my_piece::UInt8, src_sqr::UInt64, dest_sqr::UInt64; promotion_to::UInt8=NONE, en_passant_sqr::UInt64=UInt64(0))
    # move is off the board
    if dest_sqr==0
        return BLOCKED
    end

    o = occupied_by(b,dest_sqr)

    # move is blocked by one of my own pieces
    if o==my_color
        return BLOCKED
    end

    # move is a capturing move
    if o!=NONE
        m = Move(my_color, my_piece, src_sqr, dest_sqr, promotion_to=promotion_to)
        push!(moves, m)
        return BLOCKED
    end

    # move to an empty square
    m = Move(my_color, my_piece, src_sqr, dest_sqr, promotion_to=promotion_to, sqr_ep=en_passant_sqr)
    push!(moves, m)

    return UNBLOCKED
end



function generate_moves(b::Board, white_to_move::Bool, generate_only_attacking_moves=false)
    my_color, enemy_color = white_to_move ? (WHITE, BLACK) : (BLACK, WHITE)
    moves = Move[]

    attacking_moves = []
    attacked_squares = []
    if !generate_only_attacking_moves
        attacking_moves = generate_moves(b, !white_to_move, true)
        attacked_squares = [m.sqr_dest for m in attacking_moves]
    end

    for square_index in 1:64
        sqr = UInt64(1) << (square_index-1)

        occupied = occupied_by(b,sqr)
        if occupied==NONE || occupied==enemy_color
            continue
        end

        # n.b. ÷ gives integer quotient like div()
        rank = (square_index-1)÷8 + 1

        # kings moves
        king = sqr & b.kings
        if king > 0
            new_sqr = (sqr>>9) & ~FILE_H
            if new_sqr ∉ attacked_squares  # can't move into check
                add_move!(moves, b, my_color, KING, sqr, new_sqr)
            end
            new_sqr = (sqr>>8)
            if new_sqr ∉ attacked_squares  # can't move into check
                add_move!(moves, b, my_color, KING, sqr, new_sqr)
            end
            new_sqr = (sqr>>7) & ~FILE_A
            if new_sqr ∉ attacked_squares  # can't move into check
                add_move!(moves, b, my_color, KING, sqr, new_sqr)
            end
            new_sqr = (sqr>>1) & ~FILE_H
            if new_sqr ∉ attacked_squares  # can't move into check
                add_move!(moves, b, my_color, KING, sqr, new_sqr)
            end
            new_sqr = (sqr<<1) & ~FILE_A
            if new_sqr ∉ attacked_squares  # can't move into check
                add_move!(moves, b, my_color, KING, sqr, new_sqr)
            end
            new_sqr = (sqr<<7) & ~FILE_H
            if new_sqr ∉ attacked_squares  # can't move into check
                add_move!(moves, b, my_color, KING, sqr, new_sqr)
            end
            new_sqr = (sqr<<8)
            if new_sqr ∉ attacked_squares  # can't move into check
                add_move!(moves, b, my_color, KING, sqr, new_sqr)
            end
            new_sqr = (sqr<<9) & ~FILE_A
            if new_sqr ∉ attacked_squares  # can't move into check
                add_move!(moves, b, my_color, KING, sqr, new_sqr)
            end

            # castling kingside (allows for chess960 castling too)
            if !generate_only_attacking_moves
                travel_sqrs = []
                if my_color == WHITE
                    # check for castling rights
                    if b.castling_rights & CASTLING_RIGHTS_WHITE_KINGSIDE > 0
                        travel_sqrs = [SQUARE_F1, SQUARE_G1]
                    end
                elseif my_color == BLACK
                    # check for castling rights
                    if b.castling_rights & CASTLING_RIGHTS_BLACK_KINGSIDE > 0
                        travel_sqrs = [SQUARE_F8, SQUARE_G8]
                    end
                end

                if length(travel_sqrs)>0 &&
                    # check that the travel squares are empty
                    reduce(&, Bool[piece_type_on_sqr(b, s)==NONE for s in travel_sqrs]) &&
                    # check that king's traversal squares are not attacked
                    reduce(&, Bool[s ∉ attacked_squares for s in travel_sqrs])
                        push!(moves, Move(my_color, KING, sqr, travel_sqrs[end], castling=CASTLING_RIGHTS_WHITE_KINGSIDE) )
                end

                # castling queenside (allows for chess960 castling too)
                travel_sqrs = []
                if my_color == WHITE
                    # check for castling rights
                    if b.castling_rights & CASTLING_RIGHTS_WHITE_QUEENSIDE > 0
                        travel_sqrs = [SQUARE_D1, SQUARE_C1]
                    end
                elseif my_color == BLACK
                    # check for castling rights
                    if b.castling_rights & CASTLING_RIGHTS_BLACK_QUEENSIDE > 0
                        travel_sqrs = [SQUARE_D8, SQUARE_C8]
                    end
                end
                if length(travel_sqrs)>0 &&
                    # check that the travel squares are empty
                    reduce(&, Bool[piece_type_on_sqr(b, s)==NONE for s in travel_sqrs]) &&
                    # check that king's traversal squares are not attacked
                    reduce(&, Bool[s ∉ attacked_squares for s in travel_sqrs])
                        push!(moves, Move(my_color, KING, sqr, travel_sqrs[end], castling=CASTLING_RIGHTS_WHITE_QUEENSIDE) )
                end
            end # castling checks
        end # king

        # rook moves
        queen = sqr & b.queens
        rook = sqr & b.rooks
        my_piece = queen > 0 ? QUEEN : ROOK
        if rook > 0 || queen > 0
            for i in 1:7
                new_sqr = sqr>>i
                if new_sqr & FILE_H > 0
                    break
                end
                if add_move!(moves, b, my_color, my_piece, sqr, new_sqr) == BLOCKED
                    break
                end
            end
            for i in 1:7
                new_sqr = sqr<<i
                if new_sqr & FILE_A > 0
                    break
                end
                if add_move!(moves, b, my_color, my_piece, sqr, new_sqr) == BLOCKED
                    break
                end
            end
            for i in 1:7
                new_sqr = sqr>>(i*8)
                if add_move!(moves, b, my_color, my_piece, sqr, new_sqr) == BLOCKED
                    break
                end
            end
            for i in 1:7
                new_sqr = sqr<<(i*8)
                if add_move!(moves, b, my_color, my_piece, sqr, new_sqr) == BLOCKED
                    break
                end
            end
        end

        # bishop moves
        bishop = sqr & b.bishops
        my_piece = queen > 0 ? QUEEN : BISHOP
        if bishop > 0 || queen > 0
            for i in 1:7
                new_sqr = sqr>>(i*9)
                if new_sqr & FILE_H > 0
                    break
                end
                if add_move!(moves, b, my_color, my_piece, sqr, new_sqr) == BLOCKED
                    break
                end
            end
            for i in 1:7
                new_sqr = sqr>>(i*7)
                if new_sqr & FILE_A > 0
                    break
                end
                if add_move!(moves, b, my_color, my_piece, sqr, new_sqr) == BLOCKED
                    break
                end
            end
            for i in 1:7
                new_sqr = sqr<<(i*7)
                if new_sqr & FILE_H > 0
                    break
                end
                if add_move!(moves, b, my_color, my_piece, sqr, new_sqr) == BLOCKED
                    break
                end
            end
            for i in 1:7
                new_sqr = sqr<<(i*9)
                if new_sqr & FILE_A > 0
                    break
                end
                if add_move!(moves, b, my_color, my_piece, sqr, new_sqr) == BLOCKED
                    break
                end
            end
        end

        # knight moves
        knight = sqr & b.knights
        if knight > 0
            add_move!(moves, b, my_color, KNIGHT, sqr, (sqr & ~FILE_A)>>17)
            add_move!(moves, b, my_color, KNIGHT, sqr, (sqr & ~FILE_AB)>>10)
            add_move!(moves, b, my_color, KNIGHT, sqr, (sqr & ~FILE_AB)<<6)
            add_move!(moves, b, my_color, KNIGHT, sqr, (sqr & ~FILE_A)<<15)

            add_move!(moves, b, my_color, KNIGHT, sqr, (sqr & ~FILE_H)>>15)
            add_move!(moves, b, my_color, KNIGHT, sqr, (sqr & ~FILE_GH)<<10)
            add_move!(moves, b, my_color, KNIGHT, sqr, (sqr & ~FILE_GH)>>6)
            add_move!(moves, b, my_color, KNIGHT, sqr, (sqr & ~FILE_H)<<17)
        end

        # pawn moves
        pawn = sqr & b.pawns
        my_piece = PAWN
        if pawn > 0
            ONE_SQUARE_FORWARD = 8
            TWO_SQUARE_FORWARD = 16
            TAKE_LEFT = 7
            TAKE_RIGHT = 9
            START_RANK = 2
            LAST_RANK = 7
            bitshift_direction = <<
            if my_color==BLACK
                TAKE_LEFT = 9
                TAKE_RIGHT = 7
                START_RANK = 7
                LAST_RANK = 2
                bitshift_direction = >>
            end
            new_sqr = bitshift_direction(sqr, ONE_SQUARE_FORWARD)
            if occupied_by(b, new_sqr) == NONE  && !generate_only_attacking_moves
                if rank == LAST_RANK
                    add_move!(moves, b, my_color, PAWN, sqr, new_sqr, promotion_to=QUEEN)
                    add_move!(moves, b, my_color, PAWN, sqr, new_sqr, promotion_to=KNIGHT)
                    add_move!(moves, b, my_color, PAWN, sqr, new_sqr, promotion_to=ROOK)
                    add_move!(moves, b, my_color, PAWN, sqr, new_sqr, promotion_to=BISHOP)
                else
                    add_move!(moves, b, my_color, PAWN, sqr, new_sqr)
                end
                if rank == START_RANK
                    new_sqr = bitshift_direction(sqr, TWO_SQUARE_FORWARD)
                    if occupied_by(b, new_sqr) == NONE
                        add_move!(moves, b, my_color, PAWN, sqr, new_sqr)
                    end
                end
            end
            new_sqr = bitshift_direction(sqr, TAKE_LEFT) & ~FILE_H
            if occupied_by(b, new_sqr) == enemy_color || generate_only_attacking_moves
                if rank == LAST_RANK
                    add_move!(moves, b, my_color, PAWN, sqr, new_sqr, promotion_to=QUEEN)
                    add_move!(moves, b, my_color, PAWN, sqr, new_sqr, promotion_to=KNIGHT)
                    add_move!(moves, b, my_color, PAWN, sqr, new_sqr, promotion_to=ROOK)
                    add_move!(moves, b, my_color, PAWN, sqr, new_sqr, promotion_to=BISHOP)
                else
                    add_move!(moves, b, my_color, PAWN, sqr, new_sqr)
                end
            end
            # en passant
            if b.last_move_pawn_double_push > 0 &&
                new_sqr == bitshift_direction(b.last_move_pawn_double_push, ONE_SQUARE_FORWARD) &&
                !generate_only_attacking_moves
                add_move!(moves, b, my_color, PAWN, sqr, new_sqr, en_passsant_sqr=b.last_move_pawn_double_push)
            end
            new_sqr = bitshift_direction(sqr, TAKE_RIGHT) & ~FILE_A
            if occupied_by(b, new_sqr) == enemy_color || generate_only_attacking_moves
                if rank == LAST_RANK
                    add_move!(moves, b, my_color, PAWN, sqr, new_sqr, promotion_to=QUEEN)
                    add_move!(moves, b, my_color, PAWN, sqr, new_sqr, promotion_to=KNIGHT)
                    add_move!(moves, b, my_color, PAWN, sqr, new_sqr, promotion_to=ROOK)
                    add_move!(moves, b, my_color, PAWN, sqr, new_sqr, promotion_to=BISHOP)
                else
                    add_move!(moves, b, my_color, PAWN, sqr, new_sqr)
                end
            end
            # en passant
            if b.last_move_pawn_double_push > 0 &&
                new_sqr == bitshift_direction(b.last_move_pawn_double_push, ONE_SQUARE_FORWARD) &&
                !generate_only_attacking_moves
                add_move!(moves, b, my_color, PAWN, sqr, new_sqr, en_passsant_sqr=b.last_move_pawn_double_push)
            end
        end  #  if pawn > 0
    end # for square_index in 1:64


    if !generate_only_attacking_moves
        # PINNED pieces
        # check for pieces pinned to the king
        #   and remove any moves by them
        # PLAN: find king's unique square
        #       find any enemy queens,rooks,bishops on same file/columm/diagonal as king
        #       check if there is only an interposing mycolor piece
        #       remove any moves by that piece away from that file/columm/diagonal
        # OR,
        # simply run the ply, make each move, and if the enemy response allows king capture,
        # remove it from the list
        illegal_moves = []
        for m in moves
            test_board = deepcopy(b)
            make_move!(test_board,m)
            kings_square = test_board.kings & (white_to_move ? test_board.white_pieces : test_board.black_pieces)
            reply_moves = generate_moves(test_board, !white_to_move, true)
            for rm in reply_moves
                if rm.sqr_dest == kings_square
                    #println(" filtering illegal mv  $(algebraic_move(m))")
                    push!(illegal_moves, m)
                    break
                end
            end
        end
        filter!(m->m∉illegal_moves, moves)
    end


    # TODO: order moves by captures first

    # TODO: order moves so that a capture of last moved piece is first

    moves
end



function make_move!(b::Board, m::Move)
    #println("function make_move!()")
    #print_algebraic(m,b)
    #print(b)
    #@show m
    #@show square_name(m.sqr_src)
    #@show square_name(m.sqr_dest)
    #printbd(b)
    #@show b.white_pieces
    #@show b.pawns
    #@show b.queens
    #@show b

    sqr_src = m.sqr_src
    sqr_dest = m.sqr_dest
    color = piece_color_on_sqr(b,sqr_src)
    assert(color!=NONE)
    moving_piece = piece_type_on_sqr(b,sqr_src)
    assert(moving_piece!=NONE)
    taken_piece = piece_type_on_sqr(b,sqr_dest)

    # remove any piece on destination square
    if taken_piece != NONE
        b.kings = b.kings & ~sqr_dest
        b.queens = b.queens & ~sqr_dest
        b.rooks = b.rooks & ~sqr_dest
        b.bishops = b.bishops & ~sqr_dest
        b.knights = b.knights & ~sqr_dest
        b.pawns = b.pawns & ~sqr_dest
        b.white_pieces = b.white_pieces & ~sqr_dest
        b.black_pieces = b.black_pieces & ~sqr_dest
    end

    # move the moving piece (remove from src, add to dest)
    if moving_piece == KING         b.kings = (b.kings & ~sqr_src) | sqr_dest
    elseif moving_piece == QUEEN    b.queens = (b.queens & ~sqr_src) | sqr_dest
    elseif moving_piece == ROOK     b.rooks = (b.rooks & ~sqr_src) | sqr_dest
    elseif moving_piece == BISHOP   b.bishops = (b.bishops & ~sqr_src) | sqr_dest
    elseif moving_piece == KNIGHT   b.knights = (b.knights & ~sqr_src) | sqr_dest
    elseif moving_piece == PAWN     b.pawns = (b.pawns & ~sqr_src) | sqr_dest
    end

    # set en passant marker
    b.last_move_pawn_double_push = UInt64(0)
    if moving_piece == PAWN &&
        (sqr_dest << 16 == sqr_src || sqr_src << 16 == sqr_dest)
        b.last_move_pawn_double_push = sqr_dest
    end

    # update the moving color (remove from src, add to dest)
    if (b.white_pieces & sqr_src) > 0
        b.white_pieces = (b.white_pieces & ~sqr_src) | sqr_dest
    end
    if (b.black_pieces & sqr_src) > 0
        b.black_pieces = (b.black_pieces & ~sqr_src) | sqr_dest
    end

    # en passant - remove any pawn taken by en passant
    if m.sqr_ep > 0
        b.pawns = b.pawns & ~m.sqr_ep
        b.white_pieces = b.white_pieces & ~m.sqr_ep
        b.black_pieces = b.black_pieces & ~m.sqr_ep
    end

    # pawn promotion
    if m.promotion_to > NONE
        b.pawns = b.pawns & ~sqr_dest
        if m.promotion_to == QUEEN       b.queens = b.queens | sqr_dest
        elseif m.promotion_to == KNIGHT  b.knights = b.knights | sqr_dest
        elseif m.promotion_to == ROOK    b.rooks = b.rooks | sqr_dest
        elseif m.promotion_to == BISHOP  b.bishops = b.bishops | sqr_dest
        end
        if color == WHITE      b.white_pieces = b.white_pieces | sqr_dest
        elseif color == BLACK  b.black_pieces = b.black_pieces | sqr_dest
        end
    end

    # update castling rights
    if moving_piece == KING
        if color == WHITE      b.castling_rights = b.castling_rights & ~CASTLING_RIGHTS_WHITE_ANYSIDE
        elseif color == BLACK  b.castling_rights = b.castling_rights & ~CASTLING_RIGHTS_BLACK_ANYSIDE
        end
    elseif moving_piece == ROOK
        if sqr_src == SQUARE_A1       b.castling_rights = b.castling_rights & ~CASTLING_RIGHTS_WHITE_QUEENSIDE
        elseif sqr_src == SQUARE_H1   b.castling_rights = b.castling_rights & ~CASTLING_RIGHTS_WHITE_KINGSIDE
        elseif sqr_src == SQUARE_A8   b.castling_rights = b.castling_rights & ~CASTLING_RIGHTS_BLACK_QUEENSIDE
        elseif sqr_src == SQUARE_H8   b.castling_rights = b.castling_rights & ~CASTLING_RIGHTS_BLACK_KINGSIDE
        end
    end

    # castling - move rook in addition to the king
    if m.castling > 0
        if sqr_dest == SQUARE_C1
            b.rooks = (b.rooks & ~SQUARE_A1) | SQUARE_D1
            b.white_pieces = (b.white_pieces & ~SQUARE_A1)  | SQUARE_D1
        elseif sqr_dest == SQUARE_G1
            b.rooks = (b.rooks & ~SQUARE_H1) | SQUARE_F1
            b.white_pieces = (b.white_pieces & ~SQUARE_H1) | SQUARE_F1
        elseif sqr_dest == SQUARE_C8
            b.rooks = (b.rooks & ~SQUARE_A8) | SQUARE_D8
            b.black_pieces = (b.black_pieces & ~SQUARE_A8) | SQUARE_D8
        elseif sqr_dest == SQUARE_G8
            b.rooks = (b.rooks & ~SQUARE_H8) | SQUARE_F8
            b.black_pieces = (b.black_pieces & ~SQUARE_H8) | SQUARE_F8
        end
    end

    board_validation_checks(b)

    nothing
end