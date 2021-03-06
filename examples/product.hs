fst =
    \ (a : Set) (b : Set) (p : Product a b) ->
        elim (Product a b) (\ (_ : Product a b) -> a) (\(x : a) (y : b) -> x) p;

snd =
    \ (a : Set) (b : Set) (p : Product a b) ->
        elim (Product a b) (\ (_ : Product a b) -> b) (\(x : a) (y : b) -> y) p;


product_id =
    \ (a : Set) (b : Set) (p : Product a b) ->
        elim
            (Product a b)
            (\ (_ : Product a b) -> Product a b)
            (\(x : a) (y : b) -> Pair (Product a b) x y)
            p;
