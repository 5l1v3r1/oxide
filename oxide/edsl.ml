open Syntax

(* stores the last used location *)
let gloc : source_loc ref = ref ("", (0, 0), (0, 0))
let static : source_loc = ("static", (-1, -1), (-1, -1))

(* returns a fresh location every time *)
let loc (_ : unit) : source_loc =
  let (file, (line, _), (_, _)) = !gloc
  in gloc := (file, (line + 1, 0), (line + 1, 0));
     (file, (line, 0), (line, 0))

(* resets the source location info *)
let reset (file : string) : unit =
  gloc := (file, (0, 0), (0, 0))

(* variables for use in programs *)
let (x, y, z, w, a, b, r, v) = ("x", "y", "z", "w", "a", "b", "r", "v")
let (x_mut, ref_x, ref_x_mut) = ("x_mut", "ref_x", "ref_x_mut")
(* provenance variables for use in programs *)
let (p1, p2, p3, p4, p5, p6) = ("'a", "'b", "'c", "'d", "'e", "'f")

(* function names for use in programs *)
let (gimmie) = ("gimmie")

(* short-hand for use in programs *)
let fn (name : fn_var) (evs : env_vars) (provs : provs) (tyvars : ty_var list)
    (params : (var * ty) list) (ret_ty : ty) (bounds : bounds) (body : expr) : global_entry =
  FnDef (name, evs, provs, tyvars, params, ret_ty, bounds, body)
let (@:) (var : var) (ty : ty) : var * ty = (var, ty)
let structy (tag : struct_var) (provs : prov list) (tys : ty list) : prety =
  Struct (tag, provs, tys, None)
let tupty (tys : ty list) : prety = Tup tys
let tupstruct (tag : struct_var) (provs : prov list) (tys : ty list) (exprs : expr list) : preexpr =
  TupStruct (tag, provs, tys, exprs)

let (~:) (ty : ty) : ty = ty
let u32 : ty = (static, BaseTy U32)
let bool : ty = (static, BaseTy Bool)
let unit_ty : ty = (static, BaseTy Unit)
let shrd : owned = Shared
let uniq : owned = Unique
let prod (tys : ty list) : ty = (loc(), Tup tys)
let (~&) (prov : prov_var) (omega : owned) (ty : ty) : ty =
  (loc(), Ref ((loc(), prov), omega, ty))
let uninit (ty : ty) : ty = (fst ty, Uninit ty)

let unit : expr = (static, Prim Unit)
let tru : expr = (static, Prim True)
let fls : expr = (static, Prim False)

let borrow (prov : prov_var) (omega : owned) (pi : place_expr) : expr =
  (loc(), Borrow ((loc(), prov), omega, pi))
let move (pi : place_expr) : expr = (loc(), Move pi)
let letexp (var : var) (ty : ty) (e1 : expr) (e2 : expr) : expr =
  (loc(), Let (var, ty, e1, e2))
let letbe (loc : source_loc) (var : var) (ty : ty) (e1 : expr) (e2 : expr) : expr =
  (loc, Let (var, ty, e1, e2))
let var (var : var) : place_expr = (loc(), (var, []))
let (~*) (pi : place_expr) : place_expr =
  let (loc, (root, path)) = pi
  in (loc, (root, List.append path [Deref]))
let ($.) (pi : place_expr) (idx : int) : place_expr =
  let (loc, (root, path)) = pi
  in (loc, (root, List.append path [Index idx]))
let ($.$) (pi : place_expr) (field : string) : place_expr =
  let (loc, (root, path)) = pi
  in (loc, (root, List.append path [Field field]))
let num (n : int) : expr = (loc(), Prim (Num n))
let tup (exprs : expr list) : expr = (loc(), Tup exprs)
let app (fn : expr) (envs : env list) (provs : prov_var list) (tys : ty list)
        (args : expr list) : expr =
  (loc(), App (fn, envs, List.map (fun v -> (loc(), v)) provs, tys, args))
let (~@) (fn : fn_var) : expr = (loc(), Fn fn)
let (~@@) (mv : expr) : expr =
  match mv with
  | (loc, Move (_, (var, []))) -> (loc, Fn var)
  | _ -> failwith "bad codegen: found a non-variable function name"
let cond (e1 : expr) (e2 : expr) (e3 : expr) : expr = (loc(), Branch (e1, e2, e3))
let (<==) (pi : place_expr) (e : expr) : expr = (loc(), Assign (pi, e))
let (>>) (e1 : expr) (e2 : expr) : expr = (loc(), Seq (e1, e2))

let drop : global_entry =
  (fn "drop" [] [] ["T"] ["x" @: (static, TyVar "T")] (static, BaseTy Unit) []
     (static, Prim Unit))
