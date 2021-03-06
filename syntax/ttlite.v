(*
 * The first approximation of TT Lite formalization in Coq
 * No indexed universes yet
 * Explicit eliminators are just for demonstrations
 * They are already defined by Coq automatically as XXX_rec
 *)

(* Sigma *)

Inductive Sigma (A : Type) (B : A -> Type) : Type :=
  sigma : forall (a : A) (b : B a), Sigma A B.

Definition elimSigma
  (A : Type)
  (B : A -> Type)
  (m : Sigma A B -> Type)
  (f : forall (a : A) (b : B a), m (sigma A B a b))
  (e : Sigma A B) : m e :=
  match e with
  | sigma _ _ a b => f a b
  end.

(* Sum *)

Inductive Sum (A : Type) (B : Type) : Type :=
  | inl : A -> Sum A B
  | inr : B -> Sum A B.

Definition elimSum
  (A : Type)
  (B : Type)
  (m : Sum A B -> Type)
  (f1 : forall (a : A), m (inl A B a))
  (f2 : forall (b : B), m (inr A B b))
  (e : Sum A B) : m e :=
  match e with
  | inl _ _ a => f1 a
  | inr _ _ b => f2 b
  end.

(* Falsity *)

Inductive Falsity : Type := .

Definition elimFalsity
  (m : Falsity -> Type)
  (e : Falsity) : m e := match e with end.

(* Truth *)

Inductive Truth : Type :=
  | triv : Truth.

Definition elimTruth
  (m : Truth -> Type)
  (f1 : m triv)
  (e : Truth) : m e :=
  match e with
  | triv => f1
  end.

(* Nat *)

Inductive Nat : Type :=
  | zero : Nat
  | succ : Nat -> Nat.

Fixpoint elimNat
  (m : Nat -> Type)
  (f1 : m zero)
  (f2 : forall (n : Nat) (rec : m n) , m (succ n))
  (n : Nat) : m n :=
   match n with
   | zero   => f1
   | succ n => f2 n (elimNat m f1 f2 n)
   end.

(* List *)

Inductive List (A : Type) : Type :=
  | nil : List A
  | cons : A -> List A -> List A.

Fixpoint elimList
  (A : Type)
  (m : List A -> Type)
  (f1 : m (nil A))
  (f2 : forall (x : A) (xs : List A) (r : m xs), m (cons A x xs))
  (e : List A) : m e :=
  match e with
  | nil _ =>       f1
  | cons _ x xs => f2 x xs (elimList A m f1 f2 xs)
  end.

(** Identity **)

Inductive Id (A : Type) (a : A): A -> Type :=
  refl : Id A a a.

(* Print Id_rect. *)

Definition elimId
  (A : Type)
  (a1 a2 : A)
  (m : forall (a1 a2 : A) (id : Id A a1 a2) , Type)
  (f1 : forall (a : A) , m a a (refl A a) )
  (e : Id A a1 a2) : m a1 a2 e :=
  match e with
  | refl _ _ => f1 a1
  end.

(** Bool **)

Inductive Bool : Type :=
  | false : Bool
  | true : Bool.

Definition elimBool
  (m : Bool -> Type)
  (f1 : m false)
  (f2 : m true)
  (e : Bool) : m e :=
  match e with
  | false => f1
  | true  => f2
  end.

Inductive Pair (A : Type) (B : Type) : Type :=
  | pair : A -> B -> Pair A B.

(** Pair **)

Definition elimPair
  (A : Type)
  (B : Type)
  (m : Pair A B -> Type)
  (f : forall (a: A) (b : B), m (pair A B a b))
  (e : Pair A B) : m e :=
  match e with
  | pair _ _ a b => f a b
  end.

(** Vec **)

Inductive Vec (A : Type) : Nat -> Type :=
  | vnil : Vec A zero
  | vcons : forall (n : Nat) , A -> Vec A n -> Vec A (succ n).

Fixpoint elimVec
  (A : Type)
  (m : forall (n : Nat) (_ : Vec A n) , Type)
  (f1 : m zero (vnil A))
  (f2 : forall (n : Nat) (x : A) (xs : Vec A n) (r : m n xs), m (succ n) (vcons A n x xs))
  (n : Nat)
  (v : Vec A n) : m n v :=
  match v with
  | vnil _ =>         f1
  | vcons _ n1 x xs => f2 n1 x xs (elimVec A m f1 f2 n1 xs)
  end.

(** W **)

Inductive W (A : Type) (B : A -> Type) : Type :=
  | sup : forall (a : A) , (B a -> W A B) -> W A B.

Fixpoint rec
    (A : Type)
    (B : A -> Type)
    (C : W A B -> Type)
    (d : (forall (a : A) (b : B a -> W A B) , (forall (x : B a) , C (b x)) -> C (sup A B a b)))
    (c : W A B) : C c :=
    match c with
    | (sup _ _ a b) => d a b (fun (x : B a) => rec A B C d (b x))
    end.
