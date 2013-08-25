import "examples/core.hs";

-- basic combinators for constructing
-- equality proofs from equality proofs

--   symmetry
--    a = b
--   -------
--    b = a
symm :: forall (a :: Set) (x :: a) (y :: a) (_ :: Eq a x y) . Eq a y x;
symm = (\ (a :: Set) (x :: a) (y :: a) (eq :: Eq a x y) ->
        elim (Eq a x y)
            (\ (x :: a) (y :: a) (eq_x_y :: Eq a x y) -> Eq a y x)
            (\ (x :: a) -> Refl a x)
            eq);


--   transitivity
--    x = y   y = z
--   ---------------
--        x = z
tran :: forall
             (a :: Set)
             (x :: a)
             (y :: a)
             (z :: a)
             (_ :: Eq a x y)
             (_ :: Eq a y z) .
                 Eq a x z;
tran =
  ( \ (a :: Set)
      (x :: a)
      (y :: a)
      (z :: a)
      (eq_x_y :: Eq a x y) ->
        elim
            (Eq a x y)
            (\ (x :: a) (y :: a) (eq_x_y :: Eq a x y) -> forall (z :: a) (_ :: Eq a y z) . Eq a x z)
            (\ (x :: a) (z :: a) (eq_x_z :: Eq a x z) -> eq_x_z)
             eq_x_y
             z);


--   congruence of operands
--         e1 = e2
--   -------------------
--       f e1 = f e2
cong1 :: forall
              (a :: Set)
              (b :: Set)
              (f :: forall (_ :: a) . b)
              (x :: a)
              (y :: a)
              (_ :: Eq a x y) .
                  Eq b (f x) (f y);
cong1 =
  ( \ (a :: Set) (b :: Set) (f :: forall (_ :: a) . b) (x :: a) (y :: a) (eq :: Eq a x y) ->
        elim
            (Eq a x y)
            (\ (x :: a) (y :: a) (eq_x_y :: Eq a x y) -> Eq b (f x) (f y))
            (\ (x :: a) -> Refl b (f x))
            eq);



--   congruence of operators
--         f1 = f2
--   -------------------
--       f1 e = f1 e
fcong1 :: forall
               (a :: Set)
               (b :: Set)
               (x :: a)
               (f :: forall (_ :: a) . b)
               (g :: forall (_ :: a) . b)
               (_ :: Eq (forall (_ :: a) . b) f g) .
               Eq b (f x) (g x);
fcong1 =
  ( \ (a :: Set) (b :: Set) (x :: a) (f :: forall (_ :: a) . b) (g :: forall (_ :: a) . b) (eq :: Eq (forall (_ :: a) . b) f g) ->
        elim
            (Eq (forall (_ :: a) . b) f g)
            (\ (f :: forall (_ :: a) . b) (g :: forall (_ :: a) . b) (eq_f_g :: Eq (forall (_ :: a) . b) f g) -> Eq b (f x) (g x))
            (\ (f :: forall (_ :: a) . b) -> Refl b (f x))
            eq);


--   congruence of operators and operands
--     f1 = f2   e1 = e2
--   -------------------
--       f1 e1 = f2 e2
fargCong :: forall
                 (a :: Set)
                 (b :: Set)
                 (x :: a)
                 (y :: a)
                 (f :: forall (_ :: a) . b)
                 (g :: forall (_ :: a) . b)
                 (_ :: Eq a x y)
                 (_ :: Eq (forall (_ :: a) . b) f g) .
                 Eq b (f x) (g y);

fargCong =
    ( \
        (a :: Set)
        (b :: Set)
        (x :: a)
        (y :: a)
        (f :: forall (_ :: a) . b)
        (g :: forall (_ :: a) . b)
        (eq_x_y :: Eq a x y)
        (eq_f_g :: Eq (forall (_ :: a) . b) f g)  ->
            elim
                (Eq (forall (_ :: a) . b) f g)
                (\ (f :: forall (_ :: a) . b) (g :: forall (_ :: a) . b) (eq_f_g :: Eq (forall (_ :: a) . b) f g) ->  Eq b (f x) (g y))
                (\ (f :: forall (_ :: a) . b) -> cong1 a b f x y eq_x_y)
                eq_f_g);


--   congruence of two operands
--     x1 = x2   y1 = y2
--   ---------------------
--     f x1 y1 = f x2 y2
cong2 :: forall
                     (a :: Set)
                     (b :: Set)
                     (c :: Set)
                     (f :: forall (_ :: a) (_ :: b) . c)
                     (x1 :: a)
                     (x2 :: a)
                     (eq_xs :: Eq a x1 x2)
                     (y1 :: b)
                     (y2 :: b)
                     (eq_ys :: Eq b y1 y2) .
                     Eq c (f x1 y1) (f x2 y2);
cong2 =
    (\
        (a :: Set)
        (b :: Set)
        (c :: Set)
        (f :: forall (_ :: a) (_ :: b) . c)
        (x1 :: a)
        (x2 :: a)
        (eq_xs :: Eq a x1 x2)
        (y1 :: b)
        (y2 :: b)
        (eq_ys :: Eq b y1 y2) ->
            fargCong b c y1 y2 (f x1) (f x2) eq_ys (cong1 a (forall (_ :: b) . c) f x1 x2 eq_xs)
    );

--     e1 = res   e2 = res
--   ---------------------
--          e1 = e2
proof_by_sc ::
    forall
        (A :: Set)
        (e1 :: A)
        (e2 :: A)
        (res :: A)
        (eq_e1_res :: Eq A e1 res)
        (eq_e2_res :: Eq A e2 res) .
        Eq A e1 e2;
proof_by_sc =
    \ (A :: Set)
      (e1 :: A)
      (e2 :: A)
      (res :: A)
      (eq_e1_res :: Eq A e1 res)
      (eq_e2_res :: Eq A e2 res) ->
        tran A e1 res e2 eq_e1_res (symm A e2 res eq_e2_res);

eq_id =
    \ (A :: Set) (x :: A) (y :: A) (eq_x_y :: Eq A x y) ->
        elim
            (Eq A x y)
            (\ (x :: A) (y :: A) (eq_x_y :: Eq A x y) -> Eq A x y)
            (\ (x :: A) -> Refl A x)
            eq_x_y;