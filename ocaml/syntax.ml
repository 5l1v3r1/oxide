type source_loc = int * int [@@deriving show]
type var = int [@@deriving show]
type ty_var = int [@@deriving show]
type prov_var = int [@@deriving show]

type owned = Shared | Unique [@@deriving show]
type place =
  | Var of var
  | Deref of place
  | FieldProj of place * string
  | IndexProj of place * int
[@@deriving show]

type loan = owned * place [@@deriving show]
type loans = (owned * place) list [@@deriving show]
type prov =
  | ProvVar of prov_var
  | ProvSet of loans
[@@deriving show]

type kind = Star | Prov [@@deriving show]
type base_ty = Bool | U32 | Unit [@@deriving show]
type ty =
  | BaseTy of base_ty
  | TyVar of ty_var
  | Ref of prov * owned * ty
  | Fun of prov_var list * ty_var list * ty list * place_env * ty
  | Array of ty * int
  | Slice of ty
  | Tup of ty list
[@@deriving show]
and place_env = (place * ty) list [@@deriving show]

type ann_ty = source_loc * ty [@@deriving show]

(* is the given type a sized type? *)
let is_sized (typ : ty) : bool =
  (* this exists so that we don't have to stratify our types *)
  match typ with
  | Slice _ -> false
  | _ -> true

type prim =
  | Unit
  | Num of int
  | True
  | False
[@@deriving show]

type preexpr =
  | Prim of prim
  | Move of place
  | Borrow of owned * place
  | BorrowIdx of owned * place * expr
  | BorrowSlice of owned * place * expr * expr
  | Let of var * ann_ty * expr * expr
  | Assign of place * expr
  | Seq of expr * expr
  | Fun of prov_var list * ty_var list * (var * ann_ty) list * expr
  | App of expr * prov list * ann_ty list * expr list
  | Idx of place * expr
  | Abort of string
  | Branch of expr * expr * expr
  | For of var * expr * expr
  | Tup of expr list
  | Array of expr list
  | Ptr of owned * place
and expr = source_loc * preexpr
[@@deriving show]

type value =
  | Prim of prim
  | Fun of prov_var list * ty_var list * (var * ann_ty) list * expr
  | Tup of value list
  | Array of value list
  | Ptr of owned * place
[@@deriving show]

type shape =
  | Hole
  | Prim of prim
  | Fun of prov_var list * ty_var list * (var * ann_ty) list * expr
  | Tup of unit list
  | Array of value list
  | Ptr of owned * place
[@@deriving show]

type store = (place * shape) list [@@deriving show]

type global_env = unit (* TODO: actual global context definition *)
type tyvar_env = prov_var list * ty_var list [@@deriving show]

let place_env_lookup (gamma : place_env) (x : place) : ty = List.assoc x gamma
let place_env_include (gamma : place_env) (x : place) (typ : ty) = List.cons (x, typ) gamma
let place_env_exclude (gamma : place_env) (x : place) = List.remove_assoc x gamma

type tc_error =
  | TypeMismatch of source_loc * ty * ty
  | SafetyErr of source_loc * owned * place

type 'a tc =
  | Succ of 'a
  | Fail of tc_error
