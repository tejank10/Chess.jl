# search.jl

alpha_beta_position = "6k1/5pb1/6p1/r2R4/8/2q5/1B3PP1/5RK1 w - - 0 1"

b = read_fen(alpha_beta_position)
printbd(b)

best_value, best_move, principal_variation, number_nodes_visited, t_s = negaMax(b, 0)
@show best_move
assert(algebraic_long(best_move) == "b2c3")

best_value, best_move, principal_variation, number_nodes_visited, t_s = negaMax(b, 1)
@show best_move
assert(algebraic_long(best_move) == "b2c3")

best_value, best_move, principal_variation, number_nodes_visited, t_s = negaMax(b, 2)
@show best_move
assert(algebraic_long(best_move) == "d5d8")
