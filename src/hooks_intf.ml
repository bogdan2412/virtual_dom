open! Core
open! Js_of_ocaml

module type Input = sig
  type t [@@deriving sexp_of]

  (* [combine first second] describes how more than one of the same hook should
     be merged. This function will only be used if the hooks are combined
     using [Attr.many]'s merge semantics. It is common for [t] to by
     a function type like ['a -> unit Ui_effect.t]; in this case, the proper
     implementation is probably the following:

     {[
       let combine f g event =
         Vdom.Effect.sequence_as_sibling
           (f event)
           ~unless_stopped:(fun () -> g event)
     ]} *)

  val combine : t -> t -> t
end

module type S = sig
  module State : T
  module Input : Input

  (** [init] is called the first time that this attribute is attached to a particular
      node. It is particularly responsible for producing a value of type [State.t]. The
      element that it is being attached to is not necessarily attached to the rest of the
      DOM tree. *)
  val init : Input.t -> Dom_html.element Js.t -> State.t

  (** [on_mount] specifies what happens when the element is attached to the rest of the
      DOM tree.

      If [`Schedule_immediately_after_this_dom_patch_completes] is passed, the provided
      function will be called immediately after the Vdom patch that attaches the element.
      Any exceptions thrown in the function will crash the app.

      When [`Schedule_animation_frame] is passed, the browser will call the provided
      function during the next frame via [window.requestAnimationFrame()].

      Notably, "moving" a node is usually interpreted as destroying it, and creating a new
      one. You should not assume that [on_mount] will only be called once. *)
  val on_mount
    : [ `Do_nothing
      | `Schedule_immediately_after_this_dom_patch_completes of
        Input.t -> State.t -> Dom_html.element Js.t -> unit
      | `Schedule_animation_frame of Input.t -> State.t -> Dom_html.element Js.t -> unit
      ]

  (** [update] is called when a previous attribute of the same kind existed on the vdom
      node. You get access to the [Input.t] that the previous node was created with, as
      well as the State.t for that hook, which you can mutate if you like. There is no
      guarantee that [update] will be called instead of a sequence of [destroy] followed
      by [init], so [update] should behave the same as that sequence (except it might be
      faster). *)
  val update
    :  old_input:Input.t
    -> new_input:Input.t
    -> State.t
    -> Dom_html.element Js.t
    -> unit

  (** [destroy] is called when the previous vdom has this hook, but a newer vdom tree does
      not. The last input and state are passed in alongside the element that it used to be
      attached to. *)
  val destroy : Input.t -> State.t -> Dom_html.element Js.t -> unit
end

module type Hooks = sig
  module type S = S
  module type Input = Input

  type t

  val combine : t -> t -> t
  val pack : t -> Js.Unsafe.any

  module Make (S : S) : sig
    val create : S.Input.t -> t

    module For_testing : sig
      (** The type-id provided here can be used to pull out the input value for an
          instance of this hook for testing-purposes. *)

      val type_id : S.Input.t Type_equal.Id.t
    end
  end

  val unsafe_create
    :  combine_inputs:('input -> 'input -> 'input)
    -> init:('input -> Dom_html.element Js.t -> 'input * unit * 'state)
    -> extra:'input * 'input Type_equal.Id.t
    -> update:
         ('input
          -> 'input * unit * 'state
          -> Dom_html.element Js.t
          -> 'input * unit * 'state)
    -> destroy:('input * unit * 'state -> Dom_html.element Js.t -> unit)
    -> id:('input * unit * 'state) Type_equal.Id.t
    -> t

  module For_testing : sig
    module Extra : sig
      type t =
        | T :
            { type_id : 'a Type_equal.Id.t
            ; value : 'a
            }
            -> t

      val sexp_of_t : t -> Sexp.t
    end
  end
end
