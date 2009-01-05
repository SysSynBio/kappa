let debug = false
let count_embedding = true
    (* TRUE -> count embedding 
       FALSE -> count embedding / automaorphism *)

type expr = 
    Letter of string 
	
  | Vark of string
  | Vari of (int*string)
  | Var of int 
  | Mult of (expr*expr)
  | Div of (expr*expr)
  | Eps 
  | Plus of (expr*expr)
  | Const of int 
  | Constf of float 
  | Shortcut of (string*string)

let equal_un expr = 
  match expr with 
    Const 1 | Constf 1. -> true 
  | _ -> false

let equal_zero expr = 
  match expr with 
    Const 0 | Constf 0. -> true 
  | _ -> false 

let rec simplify_expr (expr:expr) = 
  match expr with 
   
    Plus (a,x) when equal_zero a -> simplify_expr x
  | Plus(x,a) when equal_zero a -> simplify_expr x
  | Mult(a,x) when equal_un a -> simplify_expr x
  | Mult(x,a) when equal_un a -> simplify_expr x 
  | Div(x,a) when equal_un a -> simplify_expr x 
  | Plus (x,y) -> Plus(simplify_expr x,simplify_expr y)
  | Mult (x,y) -> 
      let x = simplify_expr x in
      let y = simplify_expr y in
      if x=Const 1 then y 
      else if y=Const 1 then x 
      else Mult(x,y)
  | Div  (x,y) -> 
      let x = simplify_expr x in
      let y = simplify_expr y in
      if x=y 
      then Const 1
      else  Div(x,y)
  | Constf a when float_of_int(int_of_float a)=a -> Const (int_of_float a)
  | _ -> expr

module KeyMap = Map2.Make (struct type t = expr*expr*expr*expr let compare = compare end)

module HExprMap = Map2.Make (struct type t = expr let compare = compare end)

(*let simplify2 expr = 
  let rec aux expr l = 
    match expr with 
      Plus(a,b) -> aux a (aux b l)
    | _ -> expr::l in 
  let liste_termes = List.map (fun (a,b) -> simplify_expr (Mult(Const a,b))) expr in 
  let fadd key x map = 
    let old = 
      try 
	KeyMap.find key map 
      with 
	Not_found -> [] in 
    KeyMap.add key (x::old) map in 
  let rec split input output1 output2 =  
    match input with [] -> output1,output2 
    | t::q -> 
	begin
	  match t with 
	    Mult(a,Mult(Mult(Div(b,d),c),e)) -> 
	      split 
		q 
		output1 
		(fadd  (a,b,d,e) c output2)
	  | Mult(a,Mult(Div(b,d),c)) -> 
	      split q 
		output1
		(fadd (a,b,d,Const 1) c output2)
	  | Mult(Mult(Div(b,d),c),e) -> 
	      split 
		q 
		output1 
		(fadd 
		   (Const 1,b,d,e) 
		   c 
		   output2
		   )
	  | Mult(Div(b,d),c) -> 
	      split 
		q 
		output1 
		(fadd 
		   (Const 1,b,d,Const 1) 
		   c 
		   output2
		   )
	  | _ -> 
	      split 
		q 
		(t::output1) 
		output2
	end
  in 
  let output1,output2 = split liste_termes [] KeyMap.empty in 
  let output2 = 
    KeyMap.mapi
      (fun (a,b,d,e) c ->  
	if 
	  (List.sort compare (Eps::c)) = 
	  (List.sort compare (aux d [])) 
	then 
	  Mult(a,(Mult(b,e)))
	else
	  Mult(a,(Mult(Mult(Div(b,d),List.fold_left (fun a b -> Plus(a,b)) (Const 0) c),e)))
	    ) output2 in
  let expr = 
    List.fold_left 
      (fun a b -> Plus(a,b))
      (KeyMap.fold 
	 (fun _ b c -> Plus(b,c))
	 output
	 (Const 0)
	 )
      output1 in 
  simplify_expr expr 
*)
(*let simplify_expr = simplify2 *)
      
let rec simplify2 expr = 
  let rec simplify_term_list expr (map,const) = 
    match expr with 
      Plus(a,b) -> 
	simplify_term_list a (simplify_term_list b (map,const)) 
    | Constf f -> (map,const+.f)
    | Const i -> (map,const+.(float_of_int i))
    | x -> 
	let map2,const2 = 
	  simplify_factor_list x (HExprMap.empty,1.)
	in
	let exprx' = 
	  recombine_factor_list map2 in
	let old = 
	  try 
	    HExprMap.find exprx' map 
	  with 
	    Not_found -> 0.
	in
	HExprMap.add exprx' (old+.const2) map,const 
  and
      recombine_term_list map = 
    HExprMap.fold
      (fun a b expr -> 
	if b = 1. then (Plus(a,expr))
	else if b = 0. then expr
	else Plus(Mult(Constf b,a),expr))
      map
      (Constf 0.)
  and
      simplify_factor_list expr ((map:int HExprMap.t),const) = 
    match expr with 
      Mult(a,b) -> 
	simplify_factor_list a (simplify_factor_list b (map,const)) 
    | Constf f -> (map,const*.f)
    | Const i -> (map,const*.(float_of_int i))
    | Plus _  ->
	let x' = simplify2 expr in
       	let old = 
	  try 
	    HExprMap.find x' map 
	  with 
	    Not_found -> 0
	in
	HExprMap.add x' (old+1) map,const  
    | Div(a,b) 
      -> let x' = Div(simplify2 a,simplify2 b) in 
         let old = 
	  try 
	    HExprMap.find x' map 
	  with 
	    Not_found -> 0
	in
	HExprMap.add x' (old+1) map,const  
    | _ -> 
	let x' = expr in 
         let old = 
	  try 
	    HExprMap.find x' map 
	  with 
	    Not_found -> 0
	in
	HExprMap.add x' (old+1) map,const  
	
  and
      recombine_factor_list map = 
    HExprMap.fold
      (fun a b expr -> 
	if b = 1 then Mult(a,expr)
	else if b = 0 then expr
	else 
	  let rec aux k sol = 
	    if k=0 then sol
	    else aux (k-1) (Mult(a,sol))
	  in aux b (Const 1)
	    )
      map
      (Const 1)
  in 
  simplify_expr (
  let map,cst = simplify_term_list expr (HExprMap.empty,0.) in
  Plus(Constf cst,recombine_term_list map)) 

let simplify_expr expr = simplify2 (simplify_expr  expr) 
let is_atomic expr = 
  match expr with 
   Letter _ | Eps | Var _ | Vark _ -> true
   | Constf f -> f>= 0.
   | Const a -> a>=0 
 | _ -> false 



type ('subclass,'subspecies) expr_handler = 
  {hash_subspecies:'subspecies -> (int*int);
   get_denum_handling_compatibility:(string*string*string*string)-> 'subspecies list;
   get_bond:'subclass  -> (string*string*string*string) option;
   get_fragment_extension: 'subclass -> 'subspecies list }

let expr_of_var expr_handler d = 
  match expr_handler.hash_subspecies d 
  with 
    (i,1) -> Var i
  | (i,n) -> 
      if count_embedding 
      then Var i 
      else
	Mult(Const n,Var i)
     
let expr_of_denum expr_handler d = 
  let _ = 
    if debug
    then
      print_string "Expr_of_denum\n"
  in
  List.fold_left 
    (fun expr d -> 
      Plus(expr,expr_of_var expr_handler d))
    (Eps) 
    d
    
let expr_of_atom expr_handler (a:(string*string*string*string) option) b = 
  let _ = 
    if debug
    then
      print_string "Expr_of_atom\n"
  in
  (match a 
  with 
    None -> expr_of_var expr_handler b
  | Some a -> 
      let d = expr_handler.get_denum_handling_compatibility  a in
      Div (Plus(Eps,expr_of_var expr_handler b),
	   expr_of_denum expr_handler d))
    
let expr_of_subcomponent expr_handler subcla  =
  let _ = 
    if debug
    then
      print_string "Expr_of_subcomponent\n"
  in
  let a = expr_handler.get_bond subcla  in
  let b = expr_handler.get_fragment_extension subcla   in 
  List.fold_left 
    (fun expr b -> 
      Plus(expr,
	   expr_of_atom expr_handler a b))
    (Const 0) b 
    
let expr_of_case expr_handler z = 
  let _ = 
    if debug
    then
      print_string "Expr_of_case\n"
  in
  List.fold_left 
    (fun expr subcla -> 
      Mult(expr,expr_of_subcomponent expr_handler subcla))
      (Const 1) z 
    
let expr_of_classe expr_handler rep = 
  List.fold_left 
    (fun cost z ->
      Plus(cost,
	   expr_of_case expr_handler z))
    (Const 0) rep 
    
