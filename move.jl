# move.jl


# allows for move and unmove
type Move
    sqr_src::UInt64
    sqr_dest::UInt64
    sqr_ep::UInt64
    promotion_to::Integer
    castling::UInt8

    Move(src, dest) = new(src, dest, UInt64(0), NONE, UInt8(0))
    Move(src, dest, cstl) = new(src, dest, UInt64(0), NONE, cstl)
    Move(src, dest, ep, promote) = new(src, dest, ep, promote)
end

function square_name(sqr::UInt64)
    f = ' '
    if sqr & FILE_A > 0  f = 'a'  end
    if sqr & FILE_B > 0  f = 'b'  end
    if sqr & FILE_C > 0  f = 'c'  end
    if sqr & FILE_D > 0  f = 'd'  end
    if sqr & FILE_E > 0  f = 'e'  end
    if sqr & FILE_F > 0  f = 'f'  end
    if sqr & FILE_G > 0  f = 'g'  end
    if sqr & FILE_H > 0  f = 'h'  end
    r = ' '
    if sqr & RANK_1 > 0  r = '1'  end
    if sqr & RANK_2 > 0  r = '2'  end
    if sqr & RANK_3 > 0  r = '3'  end
    if sqr & RANK_4 > 0  r = '4'  end
    if sqr & RANK_5 > 0  r = '5'  end
    if sqr & RANK_6 > 0  r = '6'  end
    if sqr & RANK_7 > 0  r = '7'  end
    if sqr & RANK_8 > 0  r = '8'  end
    "$f$r"
end

function algebraic_move(m::Move, b::Board)
    if m.castling & CASTLING_RIGHTS_WHITE_KINGSIDE > 0 ||
       m.castling & CASTLING_RIGHTS_BLACK_KINGSIDE > 0
        return "o-o"
    end

    if m.castling & CASTLING_RIGHTS_WHITE_QUEENSIDE > 0 ||
       m.castling & CASTLING_RIGHTS_BLACK_QUEENSIDE > 0
        return "o-o-o"
    end

    piece_character = character_sqr_piece(b, m.sqr_src)
    if b.pawns & m.sqr_src > 0
        piece_character = ""
    end
    sqr_name = square_name(m.sqr_dest)
    optionally_promoted_to = ' '
    if     m.promotion_to==QUEEN   optionally_promoted_to = CHARACTER_QUEEN
    elseif m.promotion_to==KNIGHT  optionally_promoted_to = CHARACTER_KNIGHT
    elseif m.promotion_to==ROOK    optionally_promoted_to = CHARACTER_ROOK
    elseif m.promotion_to==BISHOP  optionally_promoted_to = CHARACTER_BISHOP
    end

    "$piece_character $sqr_name$optionally_promoted_to"
end

function print_algebraic(m::Move, b::Board)
    println(algebraic_move(m, b) * " ")
end

function print_algebraic(moves::Array{Move,1}, b::Board)
    for m in moves
        print(algebraic_move(m, b) * " ")
    end
    println("")
end

function make_move!(b::Board, m::Move)
    board_validation_checks(b)

    sqr_src = ~m.sqr_src
    sqr_dest = m.sqr_dest

    # remove any piece on destination square
    p = piece_on_sqr(b,~sqr_dest)
    if p != NONE
        b.kings = b.kings & ~sqr_dest
        b.queens = b.queens & ~sqr_dest
        b.rooks = b.rooks & ~sqr_dest
        b.bishops = b.bishops & ~sqr_dest
        b.knights = b.knights & ~sqr_dest
        b.pawns = b.pawns & ~sqr_dest
        b.white_pieces = b.white_pieces & ~sqr_dest
        b.black_pieces = b.black_pieces & ~sqr_dest
    end

    # move the moving piece
    p = piece_on_sqr(b,~sqr_src)
    if p == KING         b.kings = (b.kings & sqr_src) | sqr_dest
    elseif p == QUEEN    b.queens = (b.queens & sqr_src) | sqr_dest
    elseif p == ROOK     b.rooks = (b.rooks & sqr_src) | sqr_dest
    elseif p == BISHOP   b.bishops = (b.bishops & sqr_src) | sqr_dest
    elseif p == KNIGHT   b.knights = (b.knights & sqr_src) | sqr_dest
    elseif p == PAWN     b.pawns = (b.pawns & sqr_src) | sqr_dest
    end

    if (b.white_pieces & ~sqr_src) > 0
        b.white_pieces = (b.white_pieces & sqr_src) | sqr_dest
    end
    if (b.black_pieces & ~sqr_src) > 0
        b.black_pieces = (b.black_pieces & sqr_src) | sqr_dest
    end

    # en passant - remove any pawn taken by en passant
    if m.sqr_ep > 0
        sqr_to_clear = ~m.sqr_ep
        b.pawns = b.pawns & sqr_to_clear
        b.white_pieces = b.white_pieces & sqr_to_clear
        b.black_pieces = b.black_pieces & sqr_to_clear
    end

    # pawn promotion
    if m.promotion_to > NONE
        b.pawns = b.pawns & ~sqr_dest
        if m.promotion_to == QUEEN       b.queens = b.queens | sqr_dest
        elseif m.promotion_to == KNIGHT  b.knights = b.knights | sqr_dest
        elseif m.promotion_to == ROOK    b.rooks = b.rooks | sqr_dest
        elseif m.promotion_to == BISHOP  b.bishops = b.bishops | sqr_dest
        end
    end

    # update castling rights
    color = color_on_sqr(b,~sqr_src)
    if p == KING
        if color == WHITE      b.castling_rights = b.castling_rights | ~CASTLING_RIGHTS_WHITE_ANYSIDE
        elseif color == BLACK  b.castling_rights = b.castling_rights | ~CASTLING_RIGHTS_BLACK_ANYSIDE
        end
    elseif p == ROOK
        if sqr_src == SQUARE_A1       b.castling_rights = b.castling_rights | ~CASTLING_RIGHTS_WHITE_QUEENSIDE
        elseif sqr_src == SQUARE_H1   b.castling_rights = b.castling_rights | ~CASTLING_RIGHTS_WHITE_KINGSIDE
        elseif sqr_src == SQUARE_A8   b.castling_rights = b.castling_rights | ~CASTLING_RIGHTS_BLACK_QUEENSIDE
        elseif sqr_src == SQUARE_H8   b.castling_rights = b.castling_rights | ~CASTLING_RIGHTS_BLACK_KINGSIDE
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

function board_validation_checks(b::Board)
    n_white_pieces = count(i->i=='1', bits(b.white_pieces))
    n_black_pieces = count(i->i=='1', bits(b.black_pieces))

    n_kings = count(i->i=='1', bits(b.kings))
    n_queens = count(i->i=='1', bits(b.queens))
    n_rooks = count(i->i=='1', bits(b.rooks))
    n_bishops = count(i->i=='1', bits(b.bishops))
    n_knights = count(i->i=='1', bits(b.knights))
    n_pawns = count(i->i=='1', bits(b.pawns))

    a = n_white_pieces + n_black_pieces
    b = n_kings + n_queens + n_rooks + n_bishops + n_knights + n_pawns
    @assert a==b  "$a  $b"
end
