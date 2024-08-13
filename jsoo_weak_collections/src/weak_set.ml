[@@@js.dummy "!! This code has been generated by gen_js_api !!"]
[@@@ocaml.warning "-7-32-39"]

open! Js_of_ocaml
open! Gen_js_api

type 'a t = Ojs.t

let rec t_of_js : 'a. (Ojs.t -> 'a) -> Ojs.t -> 'a t =
  fun (type __a) (__a_of_js : Ojs.t -> __a) (x2 : Ojs.t) -> x2

and t_to_js : 'a. ('a -> Ojs.t) -> 'a t -> Ojs.t =
  fun (type __a) (__a_to_js : __a -> Ojs.t) (x1 : Ojs.t) -> x1
;;

let create : unit -> 'a t =
  fun () -> t_of_js Obj.magic (Ojs.new_obj (Ojs.get_prop_ascii Ojs.global "WeakSet") [||])
;;

let add : 'a t -> 'a -> unit =
  fun (x5 : 'a t) (x4 : 'a) ->
  ignore (Ojs.call (t_to_js Obj.magic x5) "add" [| Obj.magic x4 |])
;;

let has : 'a t -> 'a -> bool =
  fun (x8 : 'a t) (x7 : 'a) ->
  Ojs.bool_of_js (Ojs.call (t_to_js Obj.magic x8) "has" [| Obj.magic x7 |])
;;

let delete : 'a t -> 'a -> unit =
  fun (x11 : 'a t) (x10 : 'a) ->
  ignore (Ojs.call (t_to_js Obj.magic x11) "delete" [| Obj.magic x10 |])
;;
