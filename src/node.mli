open Js_of_ocaml
open Base

(** The values associated with an Element and element like nodes. (that is in practice all
    nodes that aren't just text). *)
module Element : sig
  type t

  val tag : t -> string
  val attrs : t -> Attr.t
  val key : t -> string option
  val with_key : t -> string -> t
  val map_attrs : t -> f:(Attr.t -> Attr.t) -> t
  val add_style : t -> Css_gen.t -> t
  val add_class : t -> string -> t
  val add_classes : t -> string list -> t
end

type widget

type t =
  | None
  | Fragment of t list
  | Text of string
  | Element of Element.t
  | Widget of widget
  | Lazy of
      { key : string option
      ; t : t Lazy.t
      }

module Widget : sig
  module type S = sig
    type dom = private #Dom_html.element

    module Input : sig
      type t [@@deriving sexp_of]
    end

    module State : sig
      type t [@@deriving sexp_of]
    end

    val name : string
    val create : Input.t -> State.t * dom Js.t

    val update
      :  prev_input:Input.t
      -> input:Input.t
      -> state:State.t
      -> element:dom Js.t
      -> State.t * dom Js.t

    val destroy : prev_input:Input.t -> state:State.t -> element:dom Js.t -> unit

    (** Inside of tests, this widget can be printed and interacted with as though it were
        instead, some other kind of vdom node. Use `Custom to choose that node, or
        `Sexp_of_input to get a basic vdom node that just contains the sexp of the current
        input to the widget. *)
    val to_vdom_for_testing : [ `Custom of Input.t -> t | `Sexp_of_input ]
  end
end

type node_creator := ?key:string -> ?attrs:Attr.t list -> t list -> t
type node_creator_childless := ?key:string -> ?attrs:Attr.t list -> unit -> t

module Aliases : sig
  type nonrec node_creator = node_creator
  type nonrec node_creator_childless = node_creator_childless
end

(** [none] is the absence of a node. You can use it as a placeholder for "no content".

    In practice, it will appear as a DOM comment node, which shouldn't interfere with CSS
    or selectors. This allows for more performant and correct diffing of lists where
    elements might switch between `none` and a "real" node. *)
val none : t

(** [(none_deprecated[@alert"-deprecated"])] is a node that isn't ever mounted into the
    dom, so you can use it as a placeholder for "no content".

    It is deprecated due to poor performance characteristics when virtual_dom diffing.
    Please use [none] instead *)
val none_deprecated : t
[@@deprecated "[since 2024-05] use [none] instead"]

val fragment : t list -> t
val text : string -> t
val textf : ('a, unit, string, t) format4 -> 'a

(** {2 Browser-provided node types}
    https://developer.mozilla.org/en-US/docs/Web/HTML/Element/Heading_Elements Please keep
    this list alphabetized. *)

val a : node_creator
val abbr : node_creator
val address : node_creator
val area : node_creator_childless
val article : node_creator
val aside : node_creator
val audio : node_creator
val b : node_creator
val bdi : node_creator
val bdo : node_creator
val blockquote : node_creator
val body : node_creator
val br : node_creator_childless
val button : node_creator
val canvas : node_creator
val caption : node_creator
val cite : node_creator
val code : node_creator
val col : node_creator_childless
val colgroup : node_creator
val data : node_creator
val datalist : node_creator
val dd : node_creator
val del : node_creator
val details : node_creator
val dfn : node_creator
val dialog : node_creator
val div : node_creator
val dl : node_creator
val dt : node_creator
val em : node_creator

(* [embed] is omitted, because we don't use it. *)

val fieldset : node_creator
val figcaption : node_creator
val figure : node_creator
val footer : node_creator
val form : node_creator
val h1 : node_creator
val h2 : node_creator
val h3 : node_creator
val h4 : node_creator
val h5 : node_creator
val h6 : node_creator
val head : node_creator
val header : node_creator
val hgroup : node_creator
val hr : node_creator_childless
val html : node_creator

(* [i] is omitted because we should either use CSS, or the semantic [em]. *)

val iframe : node_creator
val img : node_creator_childless
val input : node_creator_childless
val ins : node_creator
val kbd : node_creator
val label : node_creator
val legend : node_creator
val li : node_creator

(* [link] is omitted because it could be confusing to new web devs, and Bonsai apps
   almost never need to render the <head />. *)

val map : node_creator
val mark : node_creator
val main : node_creator
val menu : node_creator
val meter : node_creator
val nav : node_creator
val noscript : node_creator

(* [object] is omitted, because we don't use it. *)

val ol : node_creator
val optgroup : node_creator
val option : node_creator
val output : node_creator
val p : node_creator
val picture : node_creator
val pre : node_creator
val progress : node_creator
val q : node_creator
val rp : node_creator
val rt : node_creator
val ruby : node_creator

(* [s] is omitted, use CSS instead. *)

val samp : node_creator

(* [script] is omitted, because Bonsai apps shouldn't be dynamically generating script
   tags.*)

val search : node_creator
val section : node_creator
val select : node_creator
val slot : node_creator
val source : node_creator
val small : node_creator
val span : node_creator
val strong : node_creator
val sub : node_creator
val summary : node_creator
val sup : node_creator
val table : node_creator
val tbody : node_creator
val td : node_creator
val template : node_creator
val textarea : node_creator
val tfoot : node_creator
val th : node_creator
val thead : node_creator
val time : node_creator

(* [title] is omitted because we don't want to break people from using variables named
   [title] if they open [Node]. *)

val tr : node_creator
val track : node_creator_childless

(* [u] is omitted, use CSS instead. *)

val ul : node_creator
val var : node_creator
val video : node_creator
val wbr : node_creator_childless

(** [sexp_for_debugging] will print out a human-readable sexp. *)
val sexp_for_debugging : ?indent:int -> Sexp.t -> t

(** [of_opt node] returns the underlying Node.t for a Some, and Node.none for a None *)
val of_opt : t option -> t

(* [lazy_] allows you to defer the computation of a virtual-dom node until
   the node is actually necessary for rendering.  This can be _very_ valuable
   in situations where a node might be computed multiple-times per frame - but
   only used once (at the end, for rendering) *)
val lazy_ : ?key:string -> t Lazy.t -> t

(** This function can be used to build a node with the tag and html content of that node
    provided as a string. If this function was called with
    [~tag:"div" ~attrs:[] ~this_html...:"<b> hello world</b>"] then the resulting node
    would be [<div><b> hello world </b></div>]

    For totally sanitized content strings, this is fine; but if a user can influence the
    value of [content] and you don't have a sanitizer, they can inject code into the page,
    so use with extreme caution! *)
val inner_html
  :  ?override_vdom_for_testing:t Lazy.t
  -> tag:string
  -> attrs:Attr.t list
  -> this_html_is_sanitized_and_is_totally_safe_trust_me:string
  -> unit
  -> t

(** Same as [inner_html] but for svg elements *)
val inner_html_svg
  :  ?override_vdom_for_testing:t Lazy.t
  -> tag:string
  -> attrs:Attr.t list
  -> this_html_is_sanitized_and_is_totally_safe_trust_me:string
  -> unit
  -> t

(** Use [input] instead of [input_deprecated]. The only difference is that [input] does
    not accept a list of child nodes, but [input_deprecated] does. HTML <input> tags are
    not meant to have any child elements. *)
val input_deprecated : node_creator
[@@deprecated "[since 2022-05] use [input] instead"]

(** [key] is used by Virtual_dom as a hint during diffing/patching *)
val create : string -> node_creator

(** Like [create] but for svg nodes (i.e. all to be placed inside <svg> tag). This is
    needed as browsers maintain separate namespaces for html and svg, and failing to use
    the correct one may result in delayed redraws. *)
val create_svg : string -> node_creator

(** Creates a new browser DOM element from a virtual-dom node. Note that calling this
    function will give you a brand new element, which you then have to put into the DOM
    yourself. Thus, you should probably not be calling this very often, since Bonsai and
    Incr_dom both take care calling this function on the top-level view node.

    The one situation where [to_dom] is useful for the typical user is with the Widget
    API, since building a Widget entails generating the browser DOM element. *)
val to_dom : t -> Dom_html.element Js.t

val to_raw : t -> Raw.Node.t

(** {v
 Creates a Node.t that has fine-grained control over the Browser DOM node.

    Callbacks
    =========

    init: Returns a Browser DOM Node and a widget state object.  The Browser
    DOM node is mounted into the dom in the location where the Node.t
    object would otherwise be.

    update: Given the previous Browser DOM Node and state, makes any changes
    necessary to either and returns a new state and Browser DOM Node.

    destroy: Called when this Node.t is removed from the Virtual_dom.
    Performs any necessary cleanup.

    Other
    =====

    The [id] is used to compare widgets, and is used to make sure that the
    state from one widget doesn't get interpreted as the state for another.
    Otherwise, you would be able to implement Obj.magic using this API.


    WARNING: While other Virtual_dom APIs shield the application from script
    injection attacks, the [Widget.create] function allows a developer to
    bypass these safeguards and manually create DOM nodes which could allow an
    attacker to change the behavior of the application or exfiltrate data.

    In using this API, you are being trusted to understand and follow security
    best-practices.
    v} *)
val widget
  :  ?vdom_for_testing:t Lazy.t
  -> ?destroy:('s -> (#Dom_html.element as 'e) Js.t -> unit)
  -> ?update:('s -> 'e Js.t -> 's * 'e Js.t)
  -> id:('s * 'e Js.t) Type_equal.Id.t
  -> init:(unit -> 's * 'e Js.t)
  -> unit
  -> t

(** [widget_of_module] is very similar to [widget], but it pulls all of the callbacks out
    into a first-class module. Read the comment for [widget] to learn more.

    It is very important that you call [widget_of_module] exactly once for any "widget
    class" that you want to construct. Otherwise, the nodes created by it won't be
    comparable against one another and the widget-diffing will just run
    [destroy, init, destroy, init] over and over. *)
val widget_of_module
  :  (module Widget.S with type Input.t = 'input)
  -> ('input -> t) Staged.t

module Patch : sig
  type node := t
  type t

  val create : previous:node -> current:node -> t
  val apply : t -> Dom_html.element Js.t -> Dom_html.element Js.t
  val is_empty : t -> bool
end

module For_changing_dom : sig
  (** [with_on_mount_at_end f] runs [f], then runs any
      [`Schedule_immediately_after_this_dom_patch_completes] hook [on_mount]s scheduled
      during [f], and returns the result of [f].

      It should be used by any "top-level" code that changes the DOM; e.g. the
      [Bonsai_web.Start] initial patch + main loop, any portalling drivers, etc. *)
  val with_on_mount_at_end : (unit -> 'a) -> 'a
end

module Expert : sig
  val create : ?key:string -> string -> Attr.t -> Raw.Node.t Js.js_array Js.t -> t
  val create_svg : ?key:string -> string -> Attr.t -> Raw.Node.t Js.js_array Js.t -> t
end
