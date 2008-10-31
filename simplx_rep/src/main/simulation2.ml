open Mods2
open Error			
open Rule
open Data
open Experiment
open Error_handler 


module InjArray = Array_ext.Make(struct 
				   type t = (int list)*int*(int AssocArray.t) 
				   let default = ([],0,AssocArray.create 5) 
				 end)


type sim_data_type = {(*fresh_ind:int ;*)
  rules: Rule_of_int.t ;
  rule_of_name: int StringMap.t ;
  obs_ind : IntSet.t;

  (*coord[ind_r;ind_cc] -> (free_keys,fresh_key,assoc_map)*)
  injections: Coord.t InjArray.t;

  (*(#i,s)->{...;(coord_i[i_r,i_cc],i_inj);...}*)
  lift:(int*string) CoordSetArray.t ;

  flow:IntSet.t IntMap.t ;
  conflict: IntSet.t IntMap.t;
  sol:Solution.t ;
  net:Network.t ;
  n_ag:int ;
  min_rate:float ;
  lab: Experiment.t ;
  inf_list: IntSet.t; (*indices of rules with current infinite rate*)
  oo: IntSet.t (*rules which have to be put to inf_list when instances>0*)
}

(*Marshalization of sim_data*)
type marshalized_sim_data_t = {
  f_rules: (int*(Rule.marshalized_t*float)) list ;
  f_rule_of_name: int StringMap.t ;
  f_obs_ind : IntSet.t;
  (*[ind_r;ind_cc] -> (free_keys,fresh_key,assoc_map)*)
  f_injections: (Coord.t (*key*) * (*--->*) (int list (*fresh_keys*) 
					     * int (*fresh_key*) 
					     * ((int*assoc) list) (*f_assoc list*)
					    )
		) list; 
  (*(#i,s)->{[i_r,i_cc,i_inj];...;[j_r,j_cc,j_ind]}*)
  f_lift:((int*string)*((Coord.t*int) list)) list ; 
  f_flow:IntSet.t IntMap.t ;
  f_conflict: IntSet.t IntMap.t;
  f_sol:Solution.marshalized_t ;
  f_net:Network.marshalized_t ;
  f_n_ag:int ;
  f_min_rate:float ;
  f_lab: Experiment.t ;
  f_inf_list: IntSet.t;
  f_oo: IntSet.t
}

let marshal sim_data = 
  {
    f_rules = Rule_of_int.fold (fun i (r,act) cont -> (i,(Rule.marshal r,act))::cont) sim_data.rules [] ;
    f_rule_of_name = sim_data.rule_of_name ;
    f_obs_ind = sim_data.obs_ind ;
    f_injections = InjArray.fold (fun coord (fresh_keys,fresh,assoc_array) cont ->
				    let f_assoc_list = 
				      AssocArray.fold (fun assoc_id assoc cont ->
							 (assoc_id,assoc)::cont
						      ) assoc_array []
				    in
				      (coord,(fresh_keys,fresh,f_assoc_list))::cont
				 ) sim_data.injections [] ;

    f_lift = CoordSetArray.fold (fun (i,s) coordSet cont -> 
				   let coordList =
				     CoordSet.fold (fun (coord_i,i_inj) cont -> (coord_i,i_inj)::cont) coordSet []
				   in
				     ((i,s),coordList)::cont
				) sim_data.lift [] ;
    f_flow = sim_data.flow ;
    f_conflict = sim_data.conflict ;
    f_sol = Solution.marshal sim_data.sol ; 
    f_net = Network.marshal sim_data.net ; 
    f_n_ag = sim_data.n_ag ; 
    f_min_rate = sim_data.min_rate ; 
    f_lab = sim_data.lab ;
    f_inf_list = sim_data.inf_list ;
    f_oo = sim_data.oo
  }

let unmarshal f_sd = 
  try
    {
      rules =
	begin
	  let size = List.length f_sd.f_rules in
	    List.fold_left (fun rule_of_int (i,(f_r,act)) -> 
			      Rule_of_int.add i (Rule.unmarshal f_r,act) rule_of_int
			   ) (Rule_of_int.empty size) f_sd.f_rules 
	end;
      rule_of_name = f_sd.f_rule_of_name ;
      obs_ind = f_sd.f_obs_ind ;
      injections = List.fold_left (fun injs (coord,(fresh_keys,fresh,f_assoc_list)) ->
				     let assocArray = 
				       List.fold_left (fun assoc_array (assoc_id,assoc) ->
							 AssocArray.add assoc_id assoc assoc_array
						      ) (AssocArray.create 1) f_assoc_list 
				     in
				       InjArray.add coord (fresh_keys,fresh,assocArray) injs
				  ) (InjArray.create 1) f_sd.f_injections ;
      
      lift = List.fold_left (fun lift ((i,s),coordList) -> 
			       let coordSet = 
				 List.fold_left (fun set (coord_i,i_inj) ->
						   CoordSet.add (coord_i,i_inj) set
						) CoordSet.empty coordList
			       in
				 CoordSetArray.add (i,s) coordSet lift
			    ) (CoordSetArray.create 1) f_sd.f_lift ;
      flow = f_sd.f_flow ;
      conflict = f_sd.f_conflict ;
      sol = Solution.unmarshal f_sd.f_sol ; 
      net = Network.unmarshal f_sd.f_net ; 
      n_ag = f_sd.f_n_ag ; 
      min_rate = f_sd.f_min_rate ; 
      lab = f_sd.f_lab ;
      inf_list = f_sd.f_inf_list ;
      oo = f_sd.f_oo
    }
  with _ -> runtime "Simulation.unmarshal: uncaught exception"

let solution_AA_create = ((Solution.AA.create 5:Agent.t Solution.AA.t))

let sd_empty() = {
  rules = Rule_of_int.empty 1 ;
  rule_of_name = StringMap.empty ;
  obs_ind = IntSet.empty;
  lift = CoordSetArray.create 100 ; (*imp*)
  injections = InjArray.create 100 ;(*imp*)
  flow = IntMap.empty ;
  conflict = IntMap.empty;
  sol = Solution.empty() ;          (*imp*)
  net = Network.empty();            (*imp*)
  n_ag = 0 ;
  min_rate = (-1.0) ;
  lab = Experiment.empty ;
  inf_list = IntSet.empty ;
  oo = IntSet.empty 
}

type sim_parameters = {
  (*simulation data*)
  init_sd : string option; (*name of the marshalized file*)

  (*Computation limits*)
  max_failure:int ; (*max number of failure when trying to apply rules*)
  
  (*Computation modes*)
  compress_mode:bool;
  iso_mode:bool ;
  gc_alarm_high:bool ;
  gc_alarm_low:bool ;
}

type sim_counters = {curr_iteration:int;
		     curr_step:int;
		     curr_time:float;
		     skipped:int;
		     compression_log: (Network.t * Network.t * Network.t * int * float) list;
		     drawers:Iso.drawers ;
		     concentrations: (float IntMap.t) IntMap.t ;
		     time_map : float IntMap.t (*step -> time*) ;
		     ticks : IntSet.t ;
		     clock_precision : int ;
		     snapshot_time : float list ;
		     snapshot_counter : int 
		    }

let empty_counters = {curr_iteration=0;
		      curr_step=0;
		      curr_time=0.0;
		      skipped=0;
		      drawers=Iso.empty_drawers 0;
		      compression_log=[];
		      concentrations=IntMap.empty;
		      time_map=IntMap.empty;
		      ticks=IntSet.empty;
		      clock_precision=0 ;
		      snapshot_time = [] ;
		      snapshot_counter = 0 ;
		     }


let init_counters () = 
  let rec init_ticks n = 
    if n > !clock_precision then (prerr_string "\n"; flush stderr;flush stdout ; IntSet.empty)
    else 
      begin
	prerr_string "_" ; flush stderr ;
	IntSet.add n (init_ticks (n+1))
      end
  in
    {curr_iteration = 0; 
     curr_step = 0 ;
     curr_time = 0.0;
     skipped = 0;
     drawers = Iso.empty_drawers !max_iter ;
     compression_log = [] ; 
     concentrations = IntMap.empty ;
     time_map = IntMap.empty ;
     ticks = init_ticks 1 ;
     clock_precision = !clock_precision ;
     snapshot_time = !Data.snapshot_time ;
     snapshot_counter = 0 
    }

exception Deadlock of (sim_data_type * sim_parameters * sim_counters)

let print_injections only_obs sim_data =
  InjArray.iter (fun coord (_,_,assoc_map) ->
		   let (i,j) = Coord.to_pair coord in
		     if not only_obs or (IntSet.mem i sim_data.obs_ind) then 
		       AssocArray.iter (fun i assoc ->
					  let str = string_of_map string_of_int string_of_int IntMap.fold assoc in
					    Printf.printf "CC[%s]:%s_%d\n" (Coord.to_string coord) str i
				       ) assoc_map ;
		     print_string "-----\n" 
		) sim_data.injections


let print_lift lift =
  (*if PortMap.is_empty lift then Printf.printf "empty\n" *)
  if CoordSetArray.is_empty lift then Printf.printf "empty\n" 
  else
    (* PortMap.iter (fun (i,s) set -> *)
    CoordSetArray.iter (fun (i,s) set -> 
			 let str = string_of_set string_of_coord CoordSet.fold set in
			   Printf.printf "(%d,%s)->%s\n" i s str
		      ) lift

let print_rules rules inf_list = 
  Rule_of_int.iter (fun i (r,inst) ->
		      let auto = match r.automorphisms with 
			  None -> (failwith "automorphisms not computed!") 
			| Some i -> if not (i=1) then (Printf.sprintf "/%d" i) else ""
		      in
		      let act = r.kinetics *. inst in
			if r.input = "" then
			  match r.flag with
			      Some flg ->
				(Printf.printf "obs[%d]: %s %f%s\n" i flg act auto; flush stdout)
			    | None -> Error.warning (Printf.sprintf "Simulation.print_rules: observation r[%d] has no flag nor input string" i) 
			else
			  if IntSet.mem i inf_list then
			    Printf.printf "r[%d]: %s $INF\n" i r.input
			  else
			    Printf.printf "r[%d]: %s %f%s\n" i r.input act auto; 
			flush stdout ;
		   ) rules


let print sim_data =
  let only_obs = if sim_data.n_ag < Data.max_sol_display then false else true
  in
    if not only_obs then
      Printf.printf "Current solution: %s\n" (Solution.kappa_of_solution ~full:true sim_data.sol);
    print_rules sim_data.rules sim_data.inf_list ;
    print_injections only_obs sim_data;
    if not only_obs then print_lift sim_data.lift 


(****************TODO HERE ASSOC_MAP <- AssocArray + modif Solution.cmo********************)
let add_rule is_obs r sim_data = 
  let sol_init = sim_data.sol
  and indice_r = r.id 
  in
  let is_fake = (r.input = "") in
  let obs_ind = if is_obs or is_fake then IntSet.add indice_r sim_data.obs_ind else sim_data.obs_ind
  in
  let injs,lift,instances = 
    IntMap.fold 
      (fun indice_cc lhs_i (injs,lift,instances) -> 
	 try
	   let precomp = IntMap.find indice_cc r.precompil in
	     (*if warn one is not sure at least a modified quark in used by the awaken rule*)
	   let assoc_map = 
	     try
	       Solution.unify ~rooted:true (precomp,lhs_i) (sol_init.Solution.agents,sol_init) 
	     with Not_found -> AssocArray.create 0
	   in
	   let length = AssocArray.size assoc_map (*IntMap.size assoc_map*) in
	   let coord_cc = Coord.of_pair (indice_r,indice_cc) in (*coordinate of lhs_i is (indice_r,indice_cc)*)
	   let injs = InjArray.add coord_cc ([],length,assoc_map) injs in
	   let instances = (float_of_int length) *. instances in 
	   let lift =
	     (*IntMap.fold*)
	     AssocArray.fold
	       (fun indice_assoc assoc_i lift ->
		  let coord_assoc = (Coord.of_pair (indice_r,indice_cc),indice_assoc) in (*coordinate of injection*)
		  let phi id_p =
		    try IntMap.find id_p assoc_i 
		    with Not_found -> Error.runtime "Simulation.add_rule: assoc invariant violation"
		  and lnk s = s^"!"
		  and inf s = s^"~"
		  in
		    Solution.AA.fold (fun id_pat ag_pat lift ->
					let id_sol = phi id_pat in
					  Agent.fold_interface 
					    (fun site (info,link) lift -> (*we add all quarks of ag_pat*)
					       let quark1 = (id_sol,lnk site)
					       and quark2 = (id_sol,inf site)
					       in 
					       let set1 = 
						 try (*PortMap.find quark1 lift*)
						   CoordSetArray.find quark1 lift
						 with Not_found -> CoordSet.empty
					       and set2 =
						 try (*PortMap.find quark2 lift*)
						   CoordSetArray.find quark2 lift
						 with Not_found -> CoordSet.empty
					       in
					       let lift =
						 if link = Agent.Wildcard then lift 
						   else 
						     let set1 = CoordSet.add coord_assoc set1 in
						       (*PortMap.add quark1 set1 lift*)
						       CoordSetArray.add quark1 set1 lift
					       in
					       if info = Agent.Wildcard then lift 
						 else
						   (*PortMap.add quark2 (CoordSet.add coord_assoc set2) lift*)
						   CoordSetArray.add quark2 (CoordSet.add coord_assoc set2) lift
					    ) ag_pat  lift
				     ) lhs_i.Solution.agents lift
	       ) assoc_map lift
	   in
	     (injs,lift,instances)
	 with Solution.Matching_failed -> (injs,lift,0.0)
      ) (r.lhs) (sim_data.injections,sim_data.lift,1.0) 
  in
    
  (*computing flow and conflict map, not efficient*)
  (*(<<) is the activation relation defined in module Rule*)
  (*(%>) is the inhibition relation defined in module Rule*)
  let flow,conflict = 
    if !cplx_hsh or !load_map then (IntMap.empty,IntMap.empty)
    else
      let flow = 
	let set = try IntMap.find indice_r sim_data.flow with Not_found -> IntSet.empty in
	  if r << r then IntMap.add indice_r (IntSet.add indice_r set) sim_data.flow else sim_data.flow
      in
	Rule_of_int.fold (fun ind' (r',_) (flow,conflict) -> 
			    if indice_r = ind' then (flow,conflict) 
			    else
			      let r',_ = Rule_of_int.find ind' sim_data.rules in
			      let flow = 
				let set = try IntMap.find indice_r flow with Not_found -> IntSet.empty in
				  if r << r' then IntMap.add indice_r (IntSet.add ind' set) flow else flow
			      in 
			      let flow = 
				let set = try IntMap.find ind' flow with Not_found -> IntSet.empty in
				  if r' << r then IntMap.add ind' (IntSet.add indice_r set) flow else flow
			      in
			      let conflict = 
				if !build_conflict then
				  let conflict = 
				    let set = try IntMap.find indice_r conflict with Not_found -> IntSet.empty in
				      if r %> r' then 
					IntMap.add indice_r (IntSet.add ind' set) conflict 
				      else conflict
				  in
				  let set = try IntMap.find ind' conflict with Not_found -> IntSet.empty in
				    if r' %> r then 
				      begin
					(*
					  Printf.printf "%s #> %s\n" (Rule.string_of_rule r')(Rule.string_of_rule r) ;
					  flush stdout ;
					*)
					IntMap.add ind' (IntSet.add indice_r set) conflict 
				      end
				    else conflict
				else
				  conflict
			      in
				(flow,conflict)
			 ) sim_data.rules (flow,sim_data.conflict)
  in
  let k_r = r.kinetics in
  let inst_r = instances in
  let rn,wrn = 
    if StringMap.mem (Rule.name r) sim_data.rule_of_name then (
      Error.warning (Printf.sprintf "Kappa file uses rule name %s multiple times" (Rule.name r)) ;
      (StringMap.add r.input indice_r sim_data.rule_of_name,true)
    )
    else
      (StringMap.add (Rule.name r) indice_r sim_data.rule_of_name,false)
  in
  let r = if wrn then {r with id = indice_r ; flag = None} else {r with id = indice_r} in
    {sim_data with
       rules = Rule_of_int.add indice_r (r,inst_r) sim_data.rules;
       rule_of_name = rn ;
       injections = injs ;
       lift = lift ;
       flow = flow ;
       conflict = conflict ;
       obs_ind = obs_ind ;
       min_rate = 
	if (sim_data.min_rate < 0.0) && not is_fake then k_r
	else 
	  if not is_fake && (k_r < sim_data.min_rate) then k_r
	  else sim_data.min_rate ;
       inf_list = if r.infinite && (int_of_float instances > 0) then IntSet.add indice_r sim_data.inf_list else sim_data.inf_list ;
       oo = if r.infinite then IntSet.add indice_r sim_data.oo else sim_data.oo
    }

let init_net net (sol_init:Solution.t) = (*linear in the size of sol_init*)
  let l_cc,_ = 
    Solution.AA.fold (fun i _ (cont,blacklist) -> 
			if IntSet.mem i blacklist then (cont,blacklist)
			else
			  let cc_i = Solution.connected_component i sol_init in
			    (cc_i::cont,IntSet.union cc_i blacklist)
		     ) sol_init.Solution.agents ([],IntSet.empty)
  in
  let rec aux l_cc net = 
    match l_cc with 
	[] -> net
      | cc_i::tl -> 
	  let modifs = 
	    IntSet.fold (fun i modif ->
			   let ag = Solution.agent_of_id i sol_init in
			     Agent.fold_interface 
			       (fun s _ pmap -> 
				  let (inf,lnk) = Agent.state ag s in
				  let state_inf = match inf with
				      Agent.Marked mk -> Rule.Init_mark (Agent.name ag,mk)
				    | Agent.Wildcard -> Rule.Init_mark (Agent.name ag,"undef")
				    | _ -> Error.runtime "Not a valid initial internal state"
				  and state_lnk = match lnk with
				      Agent.Bound -> (
					try
					  let (j,s') = Solution.get_port (i,s) sol_init in
					    Rule.Init_bound (Agent.name ag,j,s'^"!")
					with Not_found -> Error.runtime "Simulation.init_net: not a valid initial link state"
				      )
				    | Agent.Free -> Rule.Init_free (Agent.name ag)
				    | _ -> Error.runtime "Simulation.init_net: not a valid initial link state"
				  in
				    PortMap.add (i,s^"~") [state_inf] (PortMap.add (i,s^"!") [state_lnk] pmap)
			       ) ag modif
			) cc_i PortMap.empty
	  in
	  let cc_str = 
	    if not !Data.short_intro_name then Solution.kappa_of_solution ~whitelist:cc_i sol_init
	    else
	      String.concat "." (IntSet.fold 
				   (fun i cont -> 
				      let name = Agent.name (Solution.agent_of_id i sol_init) in name::cont 
				   ) cc_i []
				) 
	  in
	  let net' = Network.add_intro ("intro:"^cc_str,modifs) true net
	  in
	    aux tl net' 
  in
    aux l_cc (Network.empty())
  
let concretize sim_data abs_pos_map abs_neg_map log =
  let pt = Unix.times() in
  let t = pt.Unix.tms_utime +. pt.Unix.tms_stime +. pt.Unix.tms_cutime +. pt.Unix.tms_cstime in
  let log = Session.add_log_entry 0 "--Concretization..." log in
  let pos_map,log = 
    Data_structures.IntMap.fold (fun i cplx_set (m,log) ->
				   let r_i,_ = 
				     try Rule_of_int.find i sim_data.rules 
				     with Not_found -> runtime "Simulation.concretize: incompatible rule indices"
				   in
				   let splx_set,log =
				     Data_structures.IntSet.fold 
				       (fun j (splx_set,log) -> 
					  let r_j,_ = 
					    try Rule_of_int.find j sim_data.rules 
					    with Not_found -> runtime "Simulation.concretize: incompatible rule indices"
					  in
					    if (Rule.contains_deletion r_i) or (r_i << r_j)  
					    then (Mods2.IntSet.add j splx_set,log)
					    else 
					      let log = 
						let msg = "False positive(s) detected in activation map"
						in
						  Session.add_log_entry 4 msg log
					      in
						(splx_set,log)
				       ) cplx_set (Mods2.IntSet.empty,log)
				   in
				     (Mods2.IntMap.add i splx_set m,log)
				) abs_pos_map (Mods2.IntMap.empty,log)
  in
  let neg_map,log = 
    Data_structures.IntMap.fold (fun i cplx_set (m,log) ->
				   let r_i,_ = 
				     try Rule_of_int.find i sim_data.rules 
				     with Not_found -> runtime "Simulation.concretize: incompatible rule indices"
				   in
				   let splx_set,log =
				     Data_structures.IntSet.fold 
				       (fun j (splx_set,log) ->
					  if i=j then (splx_set,log) (*trivial inhibition relation*)
					  else
					    let r_j,_ = 
					      try Rule_of_int.find j sim_data.rules 
					      with Not_found -> runtime "Simulation.concretize: incompatible rule indices"
					    in
					      if (Rule.contains_deletion r_i) or (r_i %> r_j) 
					      then (Mods2.IntSet.add j splx_set,log)
					      else 
						let log = 
						  let msg = "False positive(s) detected in inhibition map"
						  in
						    Session.add_log_entry 4 msg log
						in
						  (splx_set,log)
				       ) cplx_set (Mods2.IntSet.empty,log)
				   in
				     (Mods2.IntMap.add i splx_set m,log)
				) abs_neg_map (Mods2.IntMap.empty,log)
  in
  let pt = Unix.times() in
  let t' = pt.Unix.tms_utime +. pt.Unix.tms_stime +. pt.Unix.tms_cutime +. pt.Unix.tms_cstime in
  let log = Session.add_log_entry 0 (Printf.sprintf "--Concretization: %f sec. CPU" (t'-.t)) log in  
    (pos_map,neg_map,log)

(*sim_data initialisation*)
let init log (rules,(sol_init:Solution.t),obs_l,exp) =
  let flag_obs = List.fold_right (fun obs set ->
				    match obs with
					Solution.Occurrence flg -> if !story_mode then set else StringSet.add flg set
				      | Solution.Story flg -> if !story_mode then StringSet.add flg set else set
				      | _ -> set 
				 ) obs_l StringSet.empty 
  in
  let r_id = (List.length rules)+1 in
  let fake_rules,_ = 
    List.fold_right (fun obs (cont,fresh_id) ->
		       match obs with
			   Solution.Concentration (flg,sol) -> 
			     let actions = IntMap.empty
			     and lhs = Solution.split sol
			     in
			     let precompil = 
			       IntMap.fold (fun i cc_i map -> 
					      IntMap.add i (Solution.recognitions_of_cc cc_i) map
					   ) lhs IntMap.empty 
			     in
			     let r =
			       {lhs = lhs ;
				rhs = sol ; (*identity*)
				precompil = precompil ;
				add = IntMap.empty ;
				actions = actions;
				corr_ag = 0 ;
				rate = -1 (*really geekish!*);
				input = "" ; (*fake rule*)
				flag = Some flg ;
				constraints = [] ;
				kinetics = 1.0 ;
				automorphisms = None ;
				n_cc = IntMap.size lhs ;
				id = fresh_id;
				infinite = false;
				abstraction = None;
			       }
			     in
			       (r::cont,fresh_id+1)
			 | _ -> (cont,fresh_id)
		    ) obs_l ([],r_id)
  in


  (************COMPLX INTERACTIONS**************)

  let pipeline_methods = Pipeline.methods () in 
  let _ = Config_complx.inhibition:=false in 
    (*converting simplx data structure to the complx one*)
  let cplx_log = pipeline_methods.Pipeline.empty_channel in 

  (*computing influence maps*)
  let (cplx_simplx:Pipeline.simplx_encoding) = 
    Some (fake_rules@rules,
	  [sol_init,1] (*JF : I would like the initial state without expansion of multiplicator coefficients, in order to avoid reanalizing the same species several time *)
	 )  
  in
  let pb = pipeline_methods.Pipeline.build_pb cplx_simplx (add_suffix (add_suffix Tools.empty_prefix "") "")  
  in 
  let abs_pos_map,abs_neg_map,log,pb = 
    if !load_map or (not !cplx_hsh) then (Data_structures.IntMap.empty,Data_structures.IntMap.empty,log,pb)
    else
      let pt = Unix.times() in
      let t = pt.Unix.tms_utime +. pt.Unix.tms_stime +. pt.Unix.tms_cutime +. pt.Unix.tms_cstime in
      let log = Session.add_log_entry 0 "--Abstracting influence map..." log in
      let _ = Config_complx.dump_chrono:=false in 
      let _ = Config_complx.inhibition:=!Data.build_conflict in (*build negative map too*)
	
      let pb,cplx_log = pipeline_methods.Pipeline.build_influence_map  "" "" 
	(add_suffix (add_suffix (add_suffix Tools.empty_prefix "") "") "")  pb cplx_log 
      in 
      let log = Session.convert_cplx_log cplx_log log in
      let pt = Unix.times() in
      let t' = pt.Unix.tms_utime +. pt.Unix.tms_stime +. pt.Unix.tms_cutime +. pt.Unix.tms_cstime in
      let log = Session.add_log_entry 0 (Printf.sprintf "--Abstraction: %f sec. CPU" (t'-.t)) log in
	match pb with 
	    None -> Error.runtime "Simulation.init: complx did not return any maps, aborting"
	  | Some pb' -> 
	      let pos_map = 
		match pb'.Pb_sig.wake_up_map with 
		    Some map -> map  
		  | None -> Error.runtime "Simulation.init: no positive map, aborting"
	      and neg_map = 
		match pb'.Pb_sig.inhibition_map with
		    Some map -> map  
		  | None -> Data_structures.IntMap.empty
	      in
		(pos_map,neg_map,log,pb) 
  in

  (*computing refinement quotient and automorphisms for real rules*)
  let (cplx_simplx:Pipeline.simplx_encoding) = 
    Some (rules,
	  (*[sol_init,1]*) [] (*JF : 
				to prevent parsing all ininital condition,
				to be impoved in the case when we want to take into account reachables
				the improvment will consist in passing the list of initial agents without repetitions
			      *)
	 )  
  in
  let pb = pipeline_methods.Pipeline.build_pb cplx_simplx (add_suffix (add_suffix Tools.empty_prefix "") "")  
  in 
  let rules,log,pb = 
    let enriched_rules,pb,cplx_log = 
      pipeline_methods.Pipeline.export_refinement_relation_maximal_and_automorphism_number 
	(add_suffix (add_suffix (add_suffix Tools.empty_prefix "") "") "")
	pb (pipeline_methods.Pipeline.empty_channel)
    in 
    let rules = (*replacing rules with enriched ones if computed*)
      match enriched_rules with
	  Some en_rules -> en_rules
	| None -> Error.runtime "Simulation.init: failed to compute automorphisms for rules"
    in
    let log = Session.convert_cplx_log cplx_log log in
      (rules,log,pb)
  in

(*computing automorphism for observables (fake rules)*)
  let (cplx_simplx:Pipeline.simplx_encoding) = 
    Some (fake_rules,
	  (*[sol_init,1]*) [] (*JF : 
				to prevent parsing all ininital condition,
				to be impoved in the case when we want to take into account reachables
				the improvment will consist in passing the list of initial agents without repetitions
			      *)
	 )  
  in
  let pb = pipeline_methods.Pipeline.build_pb cplx_simplx (add_suffix (add_suffix Tools.empty_prefix "") "")  
  in 
  let fake_rules,log,pb = 
    let enriched_rules,pb,cplx_log = 
      pipeline_methods.Pipeline.export_automorphism_number 	
	(add_suffix (add_suffix (add_suffix Tools.empty_prefix "") "") "")
	pb (pipeline_methods.Pipeline.empty_channel)
    in 
    let fake_rules = (*replacing rules with enriched ones if computed*)
      match enriched_rules with
	  Some en_rules -> en_rules
	| None -> Error.runtime "Simulation.init: failed to compute automorphisms for observables"
    in
    let log = Session.convert_cplx_log cplx_log log in
      (fake_rules,log,pb)
  in

  (*****End COMPLX interactions***********)

  let _ = Gc.full_major() in
  let rule_list = fake_rules@rules in 
  let nrule = List.length rule_list in
  let sim_data = {(sd_empty ()) with rules = Rule_of_int.empty nrule} in
  let sim_data = List.fold_left (fun sd r -> 
				   match r.flag with
				       None -> add_rule false r sd 
				     | Some flg -> (*might be a fake rule*)
					 if StringSet.mem flg flag_obs then (*to be observed*)
					   add_rule true r sd 
					 else (*rule with a name but not to be observed*)
					   add_rule false r sd 
				) {sim_data with sol = sol_init} rule_list
  in
    (*Positive and negative map construction*)
  let log,sim_data = 
    if !load_map then 
      let d = open_in_bin !serialized_map_file in
      let (flow,conflict)=(Marshal.from_channel d : Mods2.IntSet.t Mods2.IntMap.t * Mods2.IntSet.t Mods2.IntMap.t)
      in
      let log = Session.add_log_entry 0 (Printf.sprintf "--%s successfully loaded" !serialized_map_file) log 
      in
	close_in d;
	(log,{sim_data with flow = flow ; conflict = conflict})
    else 
      if not !cplx_hsh then (log,sim_data) (*done in add_rule*)
      else
	let pos_map,neg_map,log = concretize sim_data abs_pos_map abs_neg_map log in
	let log = Session.add_log_entry 0 (Printf.sprintf "--Influence map computed") log 
	in
	  (log,{sim_data with flow = pos_map ; conflict = neg_map})
  in
  let log = 
    (*Saving maps if required*)
    if !save_map then 
      let file = Filename.concat !output_dir !serialized_map_file in
      let d = open_out_bin file in 
	Marshal.to_channel d (sim_data.flow,sim_data.conflict) [] ;
	close_out d;
	Session.add_log_entry 0 (Printf.sprintf "-%s successfully saved" file) log
    else log
  in
    (log,{sim_data with n_ag = sol_init.Solution.fresh_id ; lab = exp})

let mult_kinetics flg mult sim_data =
  try
    let i = StringMap.find flg sim_data.rule_of_name in
    let r_i,inst_i = Rule_of_int.find i sim_data.rules in
    let r_i'={r_i with kinetics = r_i.kinetics *. mult} in
      {sim_data with rules = Rule_of_int.add i (r_i',inst_i) sim_data.rules}
  with Not_found -> Error.runtime ("Simulation.mult_kinetics: label "^flg^" does not match any rule.")

exception Not_applicable of int*Rule.t
exception Found of int*Rule.t
exception Assoc of int IntMap.t

let select log sim_data p =
  let get_map_opt map = 
    let (k,assoc) = (*IntMap.random*) AssocArray.random map in assoc
  in
  let activity = Rule_of_int.accval sim_data.rules 
  in
  let _ = if !debug_mode then Printf.printf "Activity:%f\n" activity ; flush stdout in
  let rec choose_rule log sim_data max_failure cpt = (*cpt = nb clashes*)
    if activity <= !Data.deadlock_sensitivity then 
      let log = Session.add_log_entry 1 ("Activity has reached zero") log 
      in
	(log,None,sim_data,cpt)
    else
      let abst_ind,ind_r,(r,inst),log = 
	try (*first trying to pick an infinitely fast rule*)
	  let ind_r = IntSet.choose sim_data.inf_list in
	  let (r,inst) = Rule_of_int.find ind_r sim_data.rules
	  in
	  let r,log = 
	    if !Data.quotient_refs then 
	      match r.Rule.abstraction with
		  None -> 
		    let log = Session.add_log_entry 1 (Printf.sprintf "Abstraction not computed for rule %s" (Rule.name r)) log 
		    in
		      (r,log)
		| Some l_abst -> 
		    begin
		      match l_abst with
			  [] -> (r,log)
			| [r_abs] -> 
			    let log = Session.add_log_entry 1 (Printf.sprintf "Using abstraction for rule %s" (Rule.name r)) log 
			    in
			      (r_abs,log)
			| _ -> (*several choices of abstraction, so making no choice at all*)
			    let log = Session.add_log_entry 1 (Printf.sprintf "Not a unique abstraction for rule %s" (Rule.name r)) log 
			    in
			      (r,log)
		    end
	    else (r,log)
	  in
	  let abst_ind = StringMap.find (Rule.name r) sim_data.rule_of_name in
	    (abst_ind,ind_r,(r,inst),log)
	with Not_found -> (*no infinite rule applies*)
	  begin
	    let ind_r,(r,inst) = 
	      try Rule_of_int.random_val sim_data.rules 
	      with exn -> Error.runtime ("Simulation.select: from Rule_of_int.random_val, received "^(Printexc.to_string exn))
	    in
	    let r,log =
	      if !Data.quotient_refs then 
		(*replacing rule r with its abstraction*)
		begin
		  match r.Rule.abstraction with
		      None -> 
			let log = Session.add_log_entry 1 (Printf.sprintf "Abstraction not computed for rule %s" (Rule.name r)) log 
			in
			  (r,log)
		    | Some l_abst -> 
			begin
			  match l_abst with
			      [] -> (r,log)
			    | [r_abs] -> (r_abs,log)
			    | _ -> (*several choices of abstraction, so making no choice at all*)
				let log = Session.add_log_entry 1 (Printf.sprintf "Not a unique abstraction for rule %s" (Rule.name r)) log 
				in
				  (r,log)
			end
		end
	      else (r,log)
	    in
	      try
		let abst_ind = StringMap.find (Rule.name r) sim_data.rule_of_name in
		  (abst_ind,ind_r,(r,inst),log)
	      with
		  Not_found -> Error.runtime ("Simulation.select: Rule "^(Rule.name r)^" not found")
	  end
      in
	if r.input = "" then Error.runtime "Simulation.select: cannot apply fake rule";
	if r.infinite then (*selection of an instance of an infinitely fast rule*)
	  let assoc_map_list = 
	    IntMap.fold (fun i lhs_i cont ->
			   let _,_,assoc_map_i = InjArray.find (Coord.of_pair (abst_ind,i)) sim_data.injections in
			     if AssocArray.size assoc_map_i = 0 then 
			       Error.runtime "Simulation.select: rule has an infinite activity but the image of a cc is empty"
			     else
			       assoc_map_i::cont
			) r.lhs []
	  in
	  let product l = 
	    List.fold_left (fun prod assoc_ar ->
			      List.fold_left (fun prod (prod_map_i,inv_prod_map_i) -> 
						let ext = 
						  AssocArray.fold (fun _ map_j prod ->
								     try 
								       let (m,im) = 
									 IntMap.fold (fun i j (map,invmap) -> 
											if IntMap.mem j invmap then raise (Not_applicable (1,r)) (*collision*)
											else
											  (IntMap.add i j map,IntMap.add j i invmap)
										     ) map_j (prod_map_i,inv_prod_map_i)
								       in
									 (m,im)::prod
								     with Not_applicable _ -> prod
								  ) assoc_ar []
						in
						  ext@prod
					     ) [] prod
			   ) [(IntMap.empty,IntMap.empty)] l
	  in
	  let prod = product assoc_map_list in
	    match prod with
		[] -> 
		  let log = Session.add_log_entry 1 (Printf.sprintf "Infinite rule r[%d] is discarded because it has only clashing instances" ind_r) log 
		  in
		    choose_rule log {sim_data with 
				       inf_list = IntSet.remove ind_r sim_data.inf_list ;
				       rules = Rule_of_int.add ind_r (r,0.0) sim_data.rules 
				    } max_failure cpt
	      | (m,_)::_ -> 
		  let log = Session.add_log_entry 1 (Printf.sprintf "Applying infinitely fast rule r[%d]" ind_r) log 
		  in
		    (log,Some (abst_ind,ind_r,m),sim_data,cpt) (*cpt doesn't matter since infinite rate rule and time advance is null*)
	else
	  try
	    let m,_ =
	      IntMap.fold (fun i lhs_i (map,invmap) -> 
			     try
			       let free_keys,fresh,assoc_map_i = 
				 InjArray.find (Coord.of_pair (abst_ind,i)) sim_data.injections in
			       let length_i = AssocArray.size assoc_map_i in
				 if length_i = 0 then raise (Not_applicable (-1,r)) 
				 else
				   let assoc_i = get_map_opt assoc_map_i 
				   in
				     IntMap.fold (fun i j (map,invmap) -> 
						    if IntMap.mem j invmap then raise (Not_applicable (1,r)) (*collision*)
						    else
						      (IntMap.add i j map,IntMap.add j i invmap)
						 ) assoc_i (map,invmap)
			     with
				 Not_found -> raise (Not_applicable (0,r))  (*not applicable because one cc has no injection*)
				   
			  ) (r.lhs) (IntMap.empty,IntMap.empty)
	    in
	      if Solution.satisfy r.constraints m sim_data.sol then 
		(log,Some (abst_ind,ind_r,m),sim_data,cpt) 
	      else raise (Not_applicable (2,r))
	  with 
	      Not_applicable (-1,r) -> runtime "Simulation.select: selected rule has no injection (error -1)"
	    | Not_applicable (0,r) -> runtime (Printf.sprintf "Simulation.select: selected rule %s has no injection (error 0)" (r.Rule.input))
	    | Not_applicable (1,r) -> 
		let log = Session.add_log_entry 1 (Printf.sprintf "Clash in rule %s" (Rule.name r)) log in
		  if max_failure < 0 then choose_rule log sim_data max_failure (cpt+1)
		  else 
		    if cpt < max_failure then choose_rule log sim_data max_failure (cpt+1) 
		    else 
		      let log = Session.add_log_entry 1 ("Max failure reached: "^(Rule.name r)) log 
		      in
			(log,None,sim_data,max_failure)
	    | Not_applicable (2,r) ->
		let log = Session.add_log_entry 1 
		  (Printf.sprintf "Application of rule %s does not satisfy constraints" (Rule.name r)) log in
		  if max_failure < 0 then choose_rule log sim_data max_failure (cpt+1)
		  else 
		    if cpt < max_failure then choose_rule log sim_data max_failure (cpt+1) 
		    else 
		      let log = Session.add_log_entry 1 ("Max failure reached: "^(Rule.name r)) log 
		      in
			(log,None,sim_data,max_failure)
			  
  in
    if (Rule_of_int.accval sim_data.rules) < sim_data.min_rate then (log,None,sim_data,0)
    else
      choose_rule log sim_data p.max_failure 0

(*Test whether assoc already belongs to assoc_map*)
let consistency_check assoc assoc_map = 
  try 
    (*IntMap.fold (fun _ m consistent -> *)
    AssocArray.fold (fun _ m consistent -> 
		       let identique = try 
			 IntMap.fold (fun i j identique -> 
					let j' = IntMap.find i assoc in if j=j' then identique else
					    raise False ) m true 
		       with False | Not_found -> false 
		       in
			 if identique then raise False 
			 else consistent 
		    ) assoc_map true
  with False -> false
    

    
let update warn r_ind assoc upd_quarks assoc_add sol sim_data p = (*!! r_ind is the indice of the abstract rule when quotient_refs is enabled !!*)
  if !debug_mode then Printf.printf "modified quarks: %s\n" (Mods2.string_of_set string_of_port PortSet.fold upd_quarks) ;
  (*negative update*)
  let t_neg = chrono 0.0 in
  let lift,injs,rules,rm_coord,mod_ids,mod_obs,inf_list = 
    PortSet.fold (fun (i,s) (lift,injs,rules,rm_coord,mod_ids,mod_obs,inf_list) ->
		    let mod_ids = (*contains modified agent id (but not deleted agent ids)*)
		      if Solution.AA.mem i sol.Solution.agents 
		      then Solution.AA.add i (Solution.agent_of_id i sol) mod_ids
		      else mod_ids
		    in
		    let coord_injs = (*injection coordinates using quark (i,s)*)
		      try 
			CoordSetArray.find (i,s) lift 
		      with Not_found -> CoordSet.empty (*lift already removed*)
		    in
		    let injs,rules,rm_coord,mod_obs,inf_list = 
		      CoordSet.fold 
			(fun (coord,assoc_ind) (injs,rules,rm_coord,mod_obs,inf_list) -> 
			   try
			     let rule_ind,cc_ind = Coord.to_pair coord in
			     let free_keys,fresh,map = 
			       InjArray.find (Coord.of_pair (rule_ind,cc_ind)) injs 
			     in
			     let size =  AssocArray.size map in
			       if size = 0 then Error.runtime "Simulation.update: map size error" ;
			       let length = float_of_int size
			       and length'= float_of_int (size - 1) 
			       in
			       let assoc = AssocArray.find assoc_ind map in
			       let map = AssocArray.remove assoc_ind map in
			       let t0 = chrono 0.0 in
			       let r,inst_rule_ind = Rule_of_int.find rule_ind rules in
			       let _ = if !Mods2.bench_mode then Bench.t_upd_rules:=!Bench.t_upd_rules +. (chrono t0) in
			       let inst_rule_ind' = (inst_rule_ind /. length) *. length' in
			       let t0 =  chrono 0.0 in
			       let rules = Rule_of_int.add rule_ind (r,inst_rule_ind') rules in
			       let inf_list = (*removing infinite rate rule with no more instances*)
				 if ((int_of_float inst_rule_ind') = 0) && (IntSet.mem rule_ind inf_list) then IntSet.remove rule_ind inf_list
				 else inf_list
			       in
			       let _ = if !Mods2.bench_mode then Bench.t_upd_rules:= !Bench.t_upd_rules +. (chrono t0) in
			       let mod_obs = 
				 (*CORRECTION BUG 11 dec 2007*)
				 if IntSet.mem rule_ind sim_data.obs_ind then 
				   match r.flag with 
				       Some s -> StringSet.add s mod_obs
				     | None -> Error.runtime "Rule.update: obs invariant violation"
				 else mod_obs
				   (*FIN CORRECTION BUG 11 dec 2007*)
			       in
				 if AssocArray.is_empty map then  
				   (InjArray.remove coord injs, 
				    rules, 
				    ((coord,assoc_ind),assoc)::rm_coord,
				    mod_obs,
				    inf_list
				   )
				 else 
				   (InjArray.add coord (assoc_ind::free_keys,fresh,map) injs, 
				    rules, 
				    ((coord,assoc_ind),assoc)::rm_coord,
				    mod_obs,
				    inf_list
				   )
			   with Not_found -> (injs,rules,rm_coord,mod_obs,inf_list) (*injection already removed*)
			) coord_injs (injs,rules,rm_coord,mod_obs,inf_list) 
		    in
		    let lift = 
		      CoordSetArray.remove (i,s) lift 
		    in 
		      (lift,injs,rules,rm_coord,mod_ids,mod_obs,inf_list)
		 ) upd_quarks (sim_data.lift,sim_data.injections,sim_data.rules,
			       [], (*rm_coord*)
			       (Implementation_choices.Clean_solution.alloc_solution solution_AA_create), (*mod_ids*)
			       StringSet.empty (*mod_obs*),
			       sim_data.inf_list
			      )
  in
  let mod_ids = IntMap.fold (fun _ i m -> Solution.AA.add i (Solution.agent_of_id i sol) m) assoc_add mod_ids in
  let lift = 
    List.fold_right
      (fun ((coord,assoc_k),assoc) lift -> (*fold on rm_coord*)
	 try
	   IntMap.fold (fun id_p id_sol lift -> (*fold on assoc --whose id is assoc_k but has been removed*)
			  try
			    let ag = 
			      Solution.AA.find id_sol sol.Solution.agents 
			    in
			      Agent.fold_interface  (fun s _ lift ->
						       let lift =
							 let cset = 
							   try 
							     CoordSetArray.find (id_sol,s^"!") lift 
							   with Not_found -> CoordSet.empty
							 in
							 let cset = 
							   CoordSet.remove (coord,assoc_k) cset
							 in
							   if CoordSet.is_empty cset then 
							     CoordSetArray.remove (id_sol,s^"!") lift 
							   else
							     CoordSetArray.add (id_sol,s^"!") cset lift
						       in
						       let cset = 
							 try 
							   CoordSetArray.find (id_sol,s^"~") lift 
							 with Not_found -> CoordSet.empty
						       in
						       let cset = 
							 CoordSet.remove (coord,assoc_k) cset
						       in
							 if CoordSet.is_empty cset then 
							   CoordSetArray.remove (id_sol,s^"~") lift
							 else
							   CoordSetArray.add (id_sol,s^"~") cset lift
						    ) ag lift
			  with Not_found -> lift (*agent has been removed so all its quarks were modified*)
		       ) assoc lift
	 with Not_found -> runtime "Simulation.update: rm_coord invariant violation"
      ) rm_coord lift
  in
  let _ = if !bench_mode then Bench.neg_upd := !Bench.neg_upd +. (chrono t_neg) in
    
  (*positive update*)    
    
  let t_pos = chrono 0.0 in
    (*candidates rules to have new injs using mod_quarks are r' such that r<<r' *)
  let next = 
    if warn && (not !cplx_hsh) then (*if rule contains a deletion and abstract positive map was not computed*)
      Rule_of_int.fold (fun i _ set -> IntSet.add i set) sim_data.rules IntSet.empty
    else
      try IntMap.find r_ind sim_data.flow with Not_found -> IntSet.empty in
    
  let assoc_list = 
    IntSet.fold (*fold on all rules that might be woken up*)
      (fun rule_ind assoc_list ->
	 let t0 = chrono 0.0 in
	 let r_i,_ = 
	   try Rule_of_int.find rule_ind sim_data.rules 
	   with Not_found -> runtime "Simulation.update: invalid rule indice"
	 in
	 let _ = if !bench_mode then Bench.t_upd_rules:=!Bench.t_upd_rules +. (chrono t0) in
	   if !debug_mode then Printf.printf "waking up r[%d]\n" rule_ind ; 
	   IntMap.fold (fun ind_cc lhs_i assoc_list -> (*for all cc[i] of the rule*)
			  try
			    let precompil = IntMap.find ind_cc r_i.precompil in
			    let assoc_map_lhs_sol = Solution.unify (precompil,lhs_i) (mod_ids,sol) in
			      if !debug_mode then Printf.printf "new injection(s) found\n" ;
			      AssocArray.fold
				(fun _ assoc_lhs_sol assoc_list ->
				   let quarks = 
				     IntMap.fold 
				       (fun i_lhs j_sol set ->
					  try
					    let ag_i = Solution.agent_of_id i_lhs lhs_i in
					      Agent.fold_interface
						(fun site (inf,lnk) set ->
						   let set =
						     match inf with
							 Agent.Wildcard -> set
						       | _ -> PortSet.add (j_sol,site^"~") set
						   in
						     match lnk with
							 Agent.Wildcard -> set
						       | _ -> PortSet.add (j_sol,site^"!") set
						) ag_i set
					  with Not_found -> 
					    runtime "Simulation.update: assoc_lhs_sol invariant violation"
				       ) assoc_lhs_sol PortSet.empty
				   in
				   let contains_modif = 
				     (*if not warn then true 
				       else*) 
				     try PortSet.fold (fun q b -> 
							 if PortSet.mem q upd_quarks then raise True
							 else b
						      ) quarks false 
				     with True -> true
				   in
				     if not contains_modif then 
				       begin
					 if !debug_mode then Printf.printf "but it is not using any modified quark\n" ;
					 assoc_list
				       end
				     else
				       (rule_ind,ind_cc,assoc_lhs_sol,quarks)::assoc_list
				) assoc_map_lhs_sol assoc_list
			  with Solution.Matching_failed -> assoc_list
		       ) r_i.lhs assoc_list
      ) next []
  in
  let _ = Implementation_choices.Clean_solution.clean_solution solution_AA_create  in
  let injections,lift,rules,mod_obs,inf_list =
    List.fold_right (fun (r_i,ind_cc,assoc,quarks) (injs,lift,rules,mod_obs,inf_list) -> 
		       
		       let free_keys,fresh,assoc_map = 
			 try InjArray.find (Coord.of_pair (r_i,ind_cc)) injs 
			 with Not_found -> ([],0,(*IntMap.empty*) AssocArray.create 1)
		       in
		       let new_key,fresh',free_keys' = 
			 match free_keys with
			     [] -> (fresh,fresh+1,[])
			   | h::tl -> (h,fresh,tl)
		       in
		       let injs = 
			 if !debug_mode then 
			   if (consistency_check assoc assoc_map) then ()
			   else (
			     Printf.printf "****Erreur: CC[%d,%d]****\n" r_i ind_cc ;
			     Printf.printf "%s\n" (string_of_set string_of_port PortSet.fold upd_quarks) 
			   ) ;
			 InjArray.add 
			   (Coord.of_pair (r_i,ind_cc)) 
			   (free_keys',fresh', AssocArray.add new_key assoc assoc_map) injs
			   
		       and lift =
			 PortSet.fold (fun q lift -> 
					 let cset = 
					   try (*PortMap.find q lift with Not_found -> CoordSet.empty in*)
					     CoordSetArray.find q lift 
					   with Not_found -> CoordSet.empty 
					 in
					   (*PortMap.add q (CoordSet.add [r_i;ind_cc;new_key] cset) lift*)
					   CoordSetArray.add q (CoordSet.add (Coord.of_pair (r_i,ind_cc),new_key) cset) lift
				      ) quarks lift
		       in
		       let rules,mod_obs,inf_list = 
			 try
			   let t0 = chrono 0.0 in
			   let r,inst_r = Rule_of_int.find r_i rules in
			   let _ = if !bench_mode then Bench.t_upd_rules:=!Bench.t_upd_rules +. (chrono t0) in
			   let inst_r' = IntMap.fold (fun cc_i _ act -> 
							let _,_,map = 
							  try InjArray.find (Coord.of_pair (r_i,cc_i)) injs 
							  with Not_found -> 
							    ([],0,(*IntMap.empty*) AssocArray.create 1)
							in
							  (float_of_int ((*IntMap.size*) AssocArray.size map)) *. act
						     ) r.lhs 1.0
			   in
			   let mod_obs = 
			     if IntSet.mem r_i sim_data.obs_ind then 
			       match r.flag with 
				   Some s -> StringSet.add s mod_obs
				 | None -> Error.runtime "Rule.update: obs invariant violation"
			     else mod_obs
			   in
			   let t0 = chrono 0.0 in
			   let rules = Rule_of_int.add r_i (r,inst_r') rules in
			   let inf_list = (*adding infinite rate rule with new instances*)
			     if ((int_of_float inst_r') > 0) && (IntSet.mem r_i sim_data.oo) then IntSet.add r_i inf_list
			     else inf_list
			   in
			   let _ = if !bench_mode then Bench.t_upd_rules:=!Bench.t_upd_rules +. (chrono t0) in
			     (rules,mod_obs,inf_list)
			 with Not_found -> runtime "Simulation.update: invalid rule indice"
		       in
			 (injs,lift,rules,mod_obs,inf_list)
		    ) assoc_list (injs,lift,rules,mod_obs,inf_list)
  in
  let t0 = chrono 0.0 in
  let r,_ = Rule_of_int.find r_ind sim_data.rules in
  let _ = if !bench_mode then Bench.t_upd_rules:=!Bench.t_upd_rules +. (chrono t0) in
  let corr = r.corr_ag in
  let sim_data =
    {sim_data with 
       lift=lift; 
       injections=injections; 
       sol=sol ;
       n_ag = sim_data.n_ag + corr ; 
       rules = Rule_of_int.restore_consistency rules;
       inf_list=inf_list
    }
  in
  let lab = sim_data.lab in
  let sim_data = 
    StringSet.fold (fun flag sim_data ->
		      try
			let indices_pert = StringMap.find flag lab.name_dep in
			let sim_data,perts,indices = 
			  IntSet.fold (fun i (sim_data,perts,indices) ->
					 let pert_i = IntMap.find i lab.perturbations in
					   if pert_i.test (sim_data.rule_of_name,sim_data.rules) 
					   then (
					     if !debug_mode then 
					       Printf.printf "Applying %s\n" (string_of_perturbation pert_i) ;
					     let (oo,inf_list,rules) = 
					       pert_i.modif (sim_data.oo,sim_data.inf_list,sim_data.rule_of_name,sim_data.rules) 
					     and perts = IntMap.remove i perts
					     and indices = IntSet.remove i indices 
					     in
					       if !debug_mode then (
						 print_string "**********\n";
						 print_rules rules sim_data.inf_list;
						 print_string "**********\n"
					       ) ;
					       ({sim_data with rules = rules ; oo=oo ; inf_list = inf_list},perts,indices)
					   )
					   else (sim_data,perts,indices)
				      ) indices_pert (sim_data,lab.perturbations,indices_pert)
			in
			let name_dep = 
			  if IntSet.is_empty indices then StringMap.remove flag lab.name_dep
			  else StringMap.add flag indices lab.name_dep
			in
			  {sim_data with lab = {lab with perturbations = perts ; name_dep = name_dep}}
		      with Not_found -> sim_data 
		   ) mod_obs sim_data
  in
  let _ = if !bench_mode then Bench.pos_upd := !Bench.pos_upd +. (chrono t_pos) in
    (sim_data,mod_obs)

let get_time_range p f =
  let f' = (f /. !time_sample) in
    (int_of_float f')

let get_step_range p s = (s / !step_sample)

let rec apply_exp p curr_time sim_data =
  match sim_data.lab.time_dep with
      (t0,i)::tl -> 
	if t0 < curr_time then
	  let pert_i = IntMap.find i sim_data.lab.perturbations in
	  let (oo,inf_list,rules) = pert_i.modif (sim_data.oo,sim_data.inf_list,sim_data.rule_of_name,sim_data.rules) in
	  let lab = {sim_data.lab with 
		       perturbations = IntMap.remove i sim_data.lab.perturbations ; 
		       time_dep = tl
		    }
	  in
	    if !debug_mode then (
	      Printf.printf "Applying %s\n" (string_of_perturbation pert_i) ;
	      print_string "**************\n";
	      print_rules rules sim_data.inf_list;
	      print_string "**************\n";
	    ) ;
	    apply_exp p curr_time {sim_data with rules = rules ; lab = lab ; oo = oo ; inf_list = inf_list}
	else sim_data
    | [] -> sim_data

let rec ticking clock c = 
  if IntSet.mem clock c.ticks then 
    begin
      prerr_string Data.tick_string ; flush stderr ; 
      ticking (clock-1) {c with ticks = IntSet.remove clock c.ticks}
    end
  else (flush stderr ; c)
      
  
let rec iter log sim_data p c =
  let p = 
    match !gc_mode with
	Some HIGH -> 
	  if p.gc_alarm_high then p 
	  else (Printf.fprintf stderr "H" ; flush stdout ; {p with gc_alarm_high=true ; gc_alarm_low=false})
      | Some LOW ->
	  if p.gc_alarm_low then p 
	  else (Printf.fprintf stderr "L" ; flush stdout ; {p with gc_alarm_high=false ; gc_alarm_low=true})
      | None -> p
  in
  let clock =
    let c_story = 
      if !story_mode then (c.clock_precision * c.curr_iteration) / !max_iter
      else 0
    in
    let c_sim = 
      if !story_mode then 0 
      else
	let t = 
	  if !max_time > 0.0 then
	    int_of_float ((float_of_int c.clock_precision *. c.curr_time) /. !max_time)
	  else 0
	and e = 
	  if !max_step > 0 then
	    (c.clock_precision * c.curr_step) / !max_step
	  else 0
	in
	  max e t
    in
      max c_story c_sim
  in
  let c = ticking clock c in
  let _ = if !debug_mode then print sim_data else () in
    if !story_mode && (c.curr_iteration = !max_iter) then (*testing stop conditions for story mode*)
      begin (*exiting event loop*)
	Printf.fprintf stderr "\n";
	flush stderr; 
	let log = Session.add_log_entry 1 (Printf.sprintf "-Exiting storification after %d iteration(s)" c.curr_iteration) log in
	  (0 (*termination*),log,sim_data,p,c)
      end
    else       
      (*Testing stop conditions for simulation mode*)
      if ((!max_time >= 0.0) && (c.curr_time > !max_time)) or ((!max_step >= 0) && (c.curr_step > !max_step)) then 
	begin (*exiting event loop*)
	  Printf.fprintf stderr "\n";
	  flush stderr; 
	    let log = Session.add_log_entry 1 (Printf.sprintf "-Event loop terminated at t=%f (%d events)" c.curr_time c.curr_step) log in
	      (0 (*termination*),log,sim_data,p,c)
	  end
	else
	  (*Continuing event loop*)
	  let sim_data = apply_exp p c.curr_time sim_data in
	  let sim_data,p =
	    if !story_mode && (!init_time <= c.curr_time) && (Network.is_empty sim_data.net) then 
	      let net = init_net Network.empty sim_data.sol in
	      let sd = {sim_data with net = net} in
		(sd, p (*{p with init_sd = copy_sd sd}*))
	    else
	      (sim_data,p)
	  in
	  let c,log= 
	    if !Data.snapshot_mode then
	      begin
		match c.snapshot_time with
		    x::tl -> 
		      if (x<=c.curr_time) then 
			let log =
			  if !cores>1 then (*distributing computation of snapshots*)
			    let th = Thread.create Session.snapshot (Solution.copy sim_data.sol,c.curr_time,c.snapshot_counter)
			    in
			      threads_id:=th::(!threads_id) ;
			      Session.add_log_entry (-1) (Printf.sprintf "Spawning a thread for snapshot at t=%f" c.curr_time) log 
			  else (*stoping process to compute snapshot*)
			    (
			      Session.snapshot (sim_data.sol,c.curr_time,c.snapshot_counter) ;
			      Session.add_log_entry (-1) (Printf.sprintf "Taking snapshot at t=%f" c.curr_time) log 
			    )
			in
			  ({c with snapshot_time = tl ; snapshot_counter = c.snapshot_counter+1},log)
		      else (c,log)
		  | [] -> (c,log)
	      end
	    else (c,log)
	  in
	  let t_select = chrono 0.0 in
	  let (log,opt,sim_data,clashes) = select log sim_data p in
	    if !bench_mode then Bench.rule_select_time := !Bench.rule_select_time +. (chrono t_select) ;
	    match opt with
		None -> (
		  let log = Session.add_log_entry 1 
		    (Printf.sprintf "Deadlock found (activity = %f)" (Rule_of_int.accval sim_data.rules)) log
		  in
		    (1 (*deadlocked*),log,sim_data,p,c)
		)
	      | Some (abst_ind,r_ind,assoc) ->
		  let activity = Rule_of_int.accval sim_data.rules in
		  let dt = 
		    if !Data.no_random_time then 1./. activity (*expectency*)
		    else Mods2.random_time_advance activity clashes 
		  in (*sums clashes+1 time advance according to activity*)
		  let _ = if !debug_mode then Printf.printf "dt=%f\n" dt in
		  let curr_time = 
		    if IntSet.mem r_ind sim_data.oo then c.curr_time 
		    else
		      c.curr_time +. dt 
		  in
		    
		  let r_abst,_ = Rule_of_int.find abst_ind sim_data.rules in
		  let r_ref,_ = Rule_of_int.find r_ind sim_data.rules in
		  let _ =
		    if !debug_mode then 
		      begin
			Printf.printf "%f,r[%d]: %s\n" curr_time r_ind (Rule.name r_ref); flush stdout;
			Printf.printf "INF: %s\n" (string_of_set string_of_int IntSet.fold sim_data.inf_list) ;
		      end
		  in
		  let t_apply = chrono 0.0 in
		  let (mq,rmq,tq,assoc_add,sol',warn) = Rule.apply r_abst assoc sim_data.sol in (*passing r_abst in order to have a mq,rmq,tq as small as possible*)
		  let _ = if !bench_mode then Bench.rule_apply_time := !Bench.rule_apply_time +. (chrono t_apply) in
		  let log = 
		    if warn then
		      Session.add_log_entry 4 ("Application of rule ["^(Rule.name r_abst)^"] was contextual") log  (*application of r_abst might be contextual when of r_ref would not*)
		    else log
		  in
		    (*merge modif quarks and removed quarks*)
		  let upd_q = PortMap.fold (fun q _ pset -> PortSet.add q pset) mq rmq in
		  let t_update = chrono 0.0 in
		  let sim_data,mod_obs = update warn abst_ind assoc upd_q assoc_add sol' sim_data p
		  in
		  let _ = if !bench_mode then Bench.update_time := !Bench.update_time +. (chrono t_update) in

		    (*story sampling mode*)
		    if !story_mode && (!init_time <= c.curr_time) then 
		      let net',modifs = 
			let modifs = PortMap.fold (fun quark test_modif pmap ->
						     PortMap.add quark test_modif pmap
						  ) tq mq
			in
			let modifs = PortSet.fold (fun quark pmap ->
						     PortMap.add quark [Rule.Remove] pmap
						  ) rmq modifs 
			in 
			  if (IntSet.mem r_ind sim_data.obs_ind) then (*rule is to be observed, so don't backtrack it!*)
			    (Network.add sol' sim_data.net (r_ref,modifs) !debug_mode false, modifs)
			  else
			    (Network.add sol' sim_data.net (r_abst,modifs) !debug_mode p.compress_mode, modifs)
		      in
			if (IntSet.mem r_ind sim_data.obs_ind) then (*if applied rule triggers storification*)
			  let flg = match r_ref.flag with Some flg -> flg | _ -> runtime "Simulation.iter: obs has no flag"
			  in
			  let h = Network.cut net' flg in
			  let h = {h with Network.name_of_agent = 
			      let n = Solution.AA.size sol'.Solution.agents in
			      let vect = Array.make n "" in
			      let rec aux k = 
				if k = n then ()
				else 
				  ((vect.(k) <- 
				      try 
					(let ag = 
					   Solution.AA.find k sol'.Solution.agents in Agent.name ag) with _ -> "");
				   aux (k+1))
			      in
			      let _ = aux 0 in
				Some vect} 
			  in
			  let drawers = (Iso.classify (h,curr_time) c.drawers p.iso_mode) 
			  in
			    if !debug_mode then begin
			      Printf.printf "Story computed, restarting\n" ; flush stdout end ; 
			    
			    let log = Session.add_log_entry (-1) "-Causal trace computed" log in
			    let init_sd = 
			      match p.init_sd with
				  None -> sim_data (*No more stories to compute*)
				| Some serialized_sim_data ->
				    let d = open_in_bin serialized_sim_data in 
				    let f_init_sd = (Marshal.from_channel d : marshalized_sim_data_t) in
				    let _ = close_in d in
				      unmarshal f_init_sd 
			    in
			      iter log (init_sd) p {c with 
						      curr_iteration = c.curr_iteration+1 ; 
						      drawers = drawers ; 
						      curr_time = 0.0 (*!init_time*); 
						      curr_step = 0
						   } 
			else (*last rule was not observable for stories*)
			  let sim_data = {sim_data with sol = sol' ; net = net'} in

			    if ((!max_time >= 0.0) && (curr_time > !max_time)) or ((!max_step >= 0) && (c.curr_step+1 > !max_step)) then
			      (*if time or event limit is reached, discarding network*)
			      let log = Session.add_log_entry 4 "-No story could be found within the given limit!" log in
			      let init_sd = 
				match p.init_sd with
				    None -> sim_data (*for type checking*)
				  | Some serialized_sim_data ->
				      let d = open_in_bin serialized_sim_data in 
				      let f_init_sd = (Marshal.from_channel d : marshalized_sim_data_t) in
				      let _ = close_in d in
					unmarshal f_init_sd 
			      in
				iter log (init_sd) p {c with 
							curr_iteration = c.curr_iteration+1 ; 
							curr_time = 0.0 (*!init_time*); 
							curr_step = 0
						     }
			    else			      
			      (*limit is not reached continuing with the same network*)
			      iter log sim_data p {c with 
						     curr_step = c.curr_step + 1 ; 
						     curr_time = curr_time
						  } 
				(*End story sampling mode*)
		    else 
		      if not !ignore_obs then (*if !ignore_obs is true there is no need to take data points*)
			begin
			  (*Simulation mode*)
			  let t_data = chrono 0.0 in (*for benchmarking*)
			  let t = 
			    if !time_mode then get_time_range p curr_time (*get the time interval corresponding to current time*)
			    else get_step_range p (c.curr_step+1) (*get the event interval corresponding to current event*)
			  in
			    if (!init_time <= curr_time) then (*take measures only if passed init time*)
			      let obs_map = 
				try IntMap.find t c.concentrations 
				with Not_found -> IntMap.empty 
			      in
			      let mod_obs = 
				if c.curr_step = 0 then (*if first event*)
				  IntSet.fold (fun i cont -> 
						 let r_obs,_ = Rule_of_int.find i sim_data.rules in
						   match r_obs.flag with
						       None -> runtime "Simulation.iter: rule has no name"
						     | Some flg -> (*Printf.printf "init %s\n" flg ;*) StringSet.add flg cont
					      ) sim_data.obs_ind StringSet.empty
				else mod_obs
			      in
			      let obs_map =
				StringSet.fold (fun flg obs_map ->
						  let i = StringMap.find flg sim_data.rule_of_name in
						  let r_obs,inst_obs = 
						    try Rule_of_int.find i sim_data.rules 
						    with Not_found -> runtime "Simulation.iter: obs not found" 
						  in
						    (*automorphism correction for obs and activity for rules*)
						  let automorphisms = 
						    match r_obs.automorphisms with 
							None -> (failwith "Automorphisms not computed") 
						      | Some i -> float_of_int i 
						  in
						  let act_obs = inst_obs /. (automorphisms *. (!rescale)) in 
						    IntMap.add i act_obs obs_map

					       ) mod_obs obs_map
			      in
				if !bench_mode then Bench.data_time := !Bench.data_time +. (chrono t_data) ;
				iter log {sim_data with sol = sol'} p 
				  {c with 
				     concentrations = IntMap.add t obs_map c.concentrations;
				     curr_step = c.curr_step + 1 ;
				     curr_time = curr_time ;
				     time_map = (*JF if !time_mode then c.time_map else*) IntMap.add t curr_time c.time_map
				  } 
			    else
			      iter log {sim_data with sol = sol'} p 
				{c with 
				   curr_step = c.curr_step + 1 ;
				   curr_time = curr_time ;
				   time_map = (*JF if !time_mode then c.time_map else*) IntMap.add t curr_time c.time_map
				} 
			end
			  (*end simulation mode*)
		      else
			(*no observation mode*)
			iter log {sim_data with sol = sol'} p 
			  {c with 
			     curr_step = c.curr_step + 1 ;
			     curr_time = curr_time 
			  } 
		      (*end no observation mode*)

let build_data concentrations time_map obs_ind =
  let data,_ =
    IntMap.fold (fun t obs_map (data,prev_val) -> 
		   IntSet.fold (fun i (data,prev_val) -> 
				  let v = 
				    try
				      IntMap.find i obs_map 
				    with Not_found -> 
				      try IntMap.find i prev_val
				      with Not_found -> 0.0
				  in
				  let data = 
				    let m = try IntMap.find t data with Not_found -> IntMap.empty in
				      IntMap.add t (IntMap.add i v m) data
				  and prev_val = IntMap.add i v prev_val 
				  in
				    (data,prev_val)
			       ) obs_ind (data,prev_val)
		) concentrations (IntMap.empty,IntMap.empty)
  in
    data
