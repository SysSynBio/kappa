all: simplx_light complx_light 
simplx_light:
	make TKREP=light TKINCLUDES="" TK_CMXA=""  KEY="without_key" simplx
complx_light:
	make TKREP=light TKINCLUDES="" TK_CMXA="" KEY="without_key" complx
shell:
	make TKREP=light TKINCLUDES="" TK_CMXA="" KEY="without_key" interplx

full: simplx_full complx_full 

simplx_full: 
	make simplx TKREP=full TKINCLUDES="-I +labltk" TK_CMXA="labltk.cmxa jpflib.cmxa frxlib.cmxa -cclib -lpthread -cclib -lXau -cclib -lXdmcp" KEY="without_key"

complx_full: 
	make complx TKREP=full TKINCLUDES="-I +labltk" TK_CMXA="labltk.cmxa jpflib.cmxa frxlib.cmxa -cclib -lpthread -cclib -lXau -cclib -lXdmcp" KEY="without_key"

with_key:
	make TKREP=light TKINCLUDES="" TK_CMXQ="" KEY="with_key" simplx
	make TKREP=light TKINCLUDES="" TK_CMXQ="" KEY="with_key" complx

top:
	make toplevel KEY=without_key 

INSTALL_DIR= /usr/bin
LOCAL_DIR?=$(HOME)/fedora/bin
VERSION?=X.YY

NAME?=hopfield
OPTIONS?=
TKREP?=light
SIMPLXREP?=simplx_rep
COMPLXREP?=complx_rep
INTERPLXREP?=interplx_rep
BIN = ./bin
KEY?=without_key

$(BIN): bin/
	mkdir bin

OCAMLC=		$(OCAMLPREFIX)ocamlc -thread
OCAMLCI=	$(OCAMLPREFIX)ocamlc -thread
OCAMLOPT= 	$(OCAMLPREFIX)ocamlopt.opt -thread
OCAMLYACC=	$(OCAMLPREFIX)ocamlyacc -v
OCAMLLEX=	$(OCAMLPREFIX)ocamllex

TKINCLUDES? = 

OCAMLINCLUDES= -I $(COMPLXREP)/lib/$(TKREP) \
		-I $(COMPLXREP)/lib/$(KEY) \
		-I $(COMPLXREP)/backend \
	        -I $(COMPLXREP)/config \
	        -I $(COMPLXREP)/tools \
	        -I $(COMPLXREP)/expr  \
	        -I $(COMPLXREP)/compressor \
                -I $(COMPLXREP)/data_structures \
                -I $(COMPLXREP)/reachability \
                -I $(COMPLXREP)/vars \
	        -I $(COMPLXREP)/abstract_expr \
                -I $(COMPLXREP)/frontend \
                -I $(COMPLXREP)/backend/parse_comment \
                -I $(COMPLXREP)/backend/contact_map \
                -I $(COMPLXREP)/lib/ \
		-I $(SIMPLXREP)/src/bnf \
		-I $(SIMPLXREP)/src/data_structures \
		-I $(SIMPLXREP)/src/kappa \
		-I $(SIMPLXREP)/src/main \
		-I $(SIMPLXREP)/src/stories \
		-I $(SIMPLXREP)/src/html_config/ \
		-I $(SIMPLXREP)/src/tools/ \
                -I $(SIMPLXREP)/lib \
		-I $(COMPLXREP)/influence_map \
                -I $(COMPLXREP)/pipeline \
                -I $(COMPLXREP)/share \
                -I $(COMPLXREP)/backend/XML \
		-I $(COMPLXREP)/backend/HTML \
		-I $(COMPLXREP)/ODE \
		-I $(COMPLXREP)/cyclical_complexes \
		-I $(COMPLXREP)/refinements \
		-I $(COMPLXREP)/isomorphism_detection \
		$(TKINCLUDES) 

OCAMLFLAGS=	$(OCAMLINCLUDES)
OCAMLLIBDIR=	$(shell ocamlc -where)
CFLAGS=		-I $(OCAMLLIBDIR) -Wall -Werror -Wno-unused -DPENTIUM_III_COMPATIBLE

# TK
TK_CMA?  = labltk.cma  jpflib.cma  frxlib.cma
TK_CMXA? = 

LIBS_MLFILES = #$(COMPLXREP)/lib/wordexp.ml
LIBS_CMOFILES = $(LIBS_MLFILES:%.ml=%.cmo)
LIBS_CMXFILES = $(LIBS_MLFILES:%.ml=%.cmx)

#LIBS_CFILES =  #$(COMPLXREP)/lib/ml_wordexp.c
#LIBS_OFILES = $(LIBS_CFILES:%.c=%.o)

#LIBSC_CMA = $(COMPLXREP)/lib/libs.cma
#LIBSC_CMXA = $(COMPLXREP)/lib/libs.cmxa

#$(LIBSC_CMA): $(LIBS_CMOFILES) $(LIBS_OFILES)
#	$(OCAMLC) -a -o $@ $+

#$(LIBSC_CMXA): $(LIBS_CMXFILES) $(LIBS_OFILES)
#	$(OCAMLOPT) -a -o $@ $+

AUTOGENML=$(SIMPLXREP)/src/bnf/kappa_parse.ml 
MLFULL? = $(COMPLXREP)/lib/$(TKREP)/superargTk.ml 

TKFILE=

OBJS = 	./$(COMPLXREP)/tools/exceptions.cmo \
	./$(COMPLXREP)/tools/error_handler.cmo \
	./$(COMPLXREP)/tools/memory_usage.cmo \
	./$(COMPLXREP)/lib/$(KEY)/key.cmo \
	./$(SIMPLXREP)/src/tools/float_pretty_printing.cmo \
	./$(SIMPLXREP)/src/tools/error.cmo \
	./$(SIMPLXREP)/src/html_config/config.cmo \
	./$(COMPLXREP)/tools/map2.cmo \
	./$(COMPLXREP)/tools/map_random.cmo \
	./$(COMPLXREP)/tools/map_with_sharing.cmo \
	./$(COMPLXREP)/tools/tools2.cmo \
	./$(COMPLXREP)/tools/unbounded_array.cmo \
	./$(SIMPLXREP)/src/data_structures/coord.cmo \
	./$(SIMPLXREP)/src/data_structures/map_ext.cmo \
	./$(COMPLXREP)/data_structures/big_array.cmo \
	./$(SIMPLXREP)/src/data_structures/array_ext.cmo\
	./$(SIMPLXREP)/src/data_structures/random_tree.cmo \
	./$(SIMPLXREP)/src/tools/stringlist.cmo \
	./$(SIMPLXREP)/src/tools/mods2.cmo \
        ./$(SIMPLXREP)/src/kappa/agent.cmo \
	./$(SIMPLXREP)/src/kappa/solution.cmo \
	./$(SIMPLXREP)/src/data_structures/longString.cmo \
	./$(SIMPLXREP)/src/kappa/species.cmo \
	./$(SIMPLXREP)/src/data_structures/val_map.cmo \
	./$(SIMPLXREP)/src/data_structures/implementation_choices.cmo \
	./$(SIMPLXREP)/src/kappa/rule.cmo \
	./$(SIMPLXREP)/src/kappa/experiment.cmo \
	./$(SIMPLXREP)/src/main/data.cmo \
	./$(SIMPLXREP)/src/stories/network.cmo \
	./$(SIMPLXREP)/src/stories/story_compressor.cmo \
	./$(COMPLXREP)/backend/parse_comment/comment_sig.cmo \
	./$(COMPLXREP)/frontend/pb_sig.cmo \
	./$(COMPLXREP)/data_structures/data_structures.cmo \
	./$(COMPLXREP)/lib/superarg.cmo \
	./$(COMPLXREP)/lib/$(TKREP)/superargTk.cmo \
	./$(COMPLXREP)/config/config_complx.cmo \
	./$(COMPLXREP)/tools/tools.cmo \
	./$(SIMPLXREP)/src/stories/iso.cmo \
	./$(COMPLXREP)/share/share.cmo \
	./$(COMPLXREP)/data_structures/hash.cmo \
	./$(COMPLXREP)/backend/contact_map/acyclicity.cmo \
        ./$(COMPLXREP)/reachability/concretization.cmo \
	./$(COMPLXREP)/reachability/count_complexes.cmo \
	./$(COMPLXREP)/vars/var.cmo \
	./$(COMPLXREP)/expr/expr.cmo \
	./$(COMPLXREP)/expr/kleenean_expr.cmo \
	./$(COMPLXREP)/abstract_expr/abstract_expr_sig.cmo \
	./$(COMPLXREP)/abstract_expr/bdd.cmo \
	./$(COMPLXREP)/abstract_expr/rough.cmo \
	./$(COMPLXREP)/abstract_expr/partition.cmo \
	./$(COMPLXREP)/backend/parse_comment/yacc.cmo \
	./$(COMPLXREP)/backend/parse_comment/lexeur.cmo \
	./$(COMPLXREP)/compressor/compressor.cmo \
	./$(COMPLXREP)/reachability/contact_map.cmo \
	./$(COMPLXREP)/reachability/reachability.cmo \
	./$(COMPLXREP)/frontend/cbng_sig.cmo \
	./$(COMPLXREP)/frontend/cbng.cmo \
	./$(SIMPLXREP)/src/bnf/kappa_parse.cmo \
        ./$(SIMPLXREP)/src/bnf/kappa_lex.cmo \
	./$(COMPLXREP)/frontend/translate.cmo \
	./$(COMPLXREP)/reachability/packing.cmo \
	./$(COMPLXREP)/influence_map/quarkification.cmo \
	./$(COMPLXREP)/backend/contact_map/neighborhood.cmo \
	./$(COMPLXREP)/backend/contact_map/output_contact_map.cmo \
	./$(COMPLXREP)/cyclical_complexes/avoid_polymere.cmo \
	./$(COMPLXREP)/refinements/refinements.cmo \
	./$(COMPLXREP)/isomorphism_detection/count_isomorphism.cmo \
	./$(COMPLXREP)/backend/XML/xml.cmo \
	./$(COMPLXREP)/backend/HTML/html.cmo \
	./$(COMPLXREP)/influence_map/influence_map.cmo \
	./$(COMPLXREP)/ODE/arithmetics.cmo \
	./$(COMPLXREP)/ODE/ode_print_sig.cmo \
	./$(COMPLXREP)/ODE/ode_print.cmo \
	./$(COMPLXREP)/ODE/annotated_contact_map.cmo \
	./$(COMPLXREP)/ODE/views.cmo \
	./$(COMPLXREP)/ODE/rooted_path.cmo \
	./$(COMPLXREP)/ODE/fragments_sig.cmo \
	./$(COMPLXREP)/ODE/fragments.cmo \
	./$(COMPLXREP)/ODE/old_fragments.cmo \
	./$(COMPLXREP)/ODE/ode_computation.cmo \
	./$(COMPLXREP)/backend/contact_map/find_cycles.cmo \
	./$(COMPLXREP)/backend/contact_map/connected_components.cmo \
	./$(COMPLXREP)/pipeline/pipeline.cmo \
	./$(SIMPLXREP)/src/main/session.cmo \
	./$(SIMPLXREP)/src/main/memory_control.cmo \
	./$(SIMPLXREP)/src/tools/bench.cmo \
	./$(SIMPLXREP)/src/main/simulation2.cmo \
	./$(SIMPLXREP)/src/html_config/HTML.cmo


SIMPLX_MAIN = ./$(SIMPLXREP)/src/main/main.ml
COMPLX_MAIN = ./$(COMPLXREP)/main.ml 
INTERPLX_MAIN = ./$(INTERPLXREP)/shell.ml

NATIVE_OBJS = $(OBJS:cmo=cmx) 
MLFILES = $(OBJS:cmo=ml) $(SIMPLX_MAIN) $(COMPLX_MAIN)

MLI =  ./$(SIMPLXREP)/src/tools/error.mli \
	./$(SIMPLXREP)/src/data_structures/coord.mli \
	./$(SIMPLXREP)/src/data_structures/map_ext.mli \
	./$(SIMPLXREP)/src/data_structures/array_ext.mli \
	./$(SIMPLXREP)/src/data_structures/longString.mli \
	./$(SIMPLXREP)/src/tools/mods2.mli \
        ./$(SIMPLXREP)/src/kappa/agent.mli \
	./$(SIMPLXREP)/src/kappa/solution.mli \
	./$(SIMPLXREP)/src/kappa/rule.mli\
	./$(SIMPLXREP)/src/bnf/kappa_parse.mli 

CMI = $(MLI:mli=cmi)
CMA = unix.cma threads.cma str.cma nums.cma
CMXA = unix.cmxa threads.cmxa str.cmxa nums.cmxa

SIMPLX_OUT = simplx
INTERPLX_OUT = interplx

LIB_OPT = $(SIMPLX_OUT).cmxa
LIB_BYTE = $(SIMPLX_OUT).cma

DOCS = $(MLI) $(OBJS:cmo=ml)
DOCREP = ./document
DOCTYPE = 

gen_doc :  
	ocamldoc -$(DOCTYPE) $(DOCS) $(OCAMLINCLUDES) -d $(DOCREP) 

html_doc : 
	make KEY=without_key DOCTYPE=html gen_doc

dot_doc :
	make KEY=without_key DOCTYPE=dot gen_doc


simplx :$(MLI) $(CMI) $(LIBSC_CMXA) $(LIB_OPT) $(SIMPLX_MAIN) $(BIN)
	$(OCAMLOPT) $(OCAMLFLAGS) $(CMXA) $(TK_CMXA) $(LIBSC_CMXA) $(LIB_OPT)  $(SIMPLX_MAIN) -o $(BIN)/$(SIMPLX_OUT)

byte :  $(MLI) $(CMI) $(LIBSC_CMA) $(LIB_BYTE) $(SIMPLX_MAIN) $(BIN)
	$(OCAMLC) $(OCAMLFLAGS) $(CMA) $(LIBSC_CMA) $(LIB_BYTE) $(SIMPLX_MAIN) -o $(BIN)/$(SIMPLX_OUT).byte

dep :  
	ocamldep $(OCAMLINCLUDES) $(MLFILES)


interplx :$(MLI) $(CMI) $(LIBSC_CMXA) $(LIB_OPT) $(INTERPLX_MAIN) $(BIN)
	$(OCAMLOPT) $(OCAMLFLAGS) $(CMXA) $(TK_CMXA) $(LIBSC_CMXA) $(LIB_OPT)  $(INTERPLX_MAIN) -o $(BIN)/$(INTERPLX_OUT)

$(SIMPLX_OUT).cmxa: $(MLI) $(CMI) $(LIBSC_CMXA) $(NATIVE_OBJS) 
	$(OCAMLOPT) $(OCAMLFLAGS) -a $(NATIVE_OBJS)  -o $(SIMPLXREP)/lib/$(SIMPLX_OUT).cmxa

$(SIMPLX_OUT).cma: $(MLI) $(CMI) $(LIBSC_CMA) $(OBJS)	
	$(OCAMLC) $(OCAMLFLAGS) -a $(OBJS) -o $(SIMPLXREP)/lib/$(SIMPLX_OUT).cma

LINE = $(OCAMLOPT) $(OCAMLFLAGS) $(TKINCLUDES) $(CMXA) $(TK_CMXA) $(LIBSC_CMXA)  $(NATIVE_OBJS) 

complx: $(LIBSC_CMXA) $(NATIVE_OBJS) $(COMPLX_MAIN)
	$(LINE) $(COMPLX_MAIN) -o $(BIN)/complx

influence_map: $(COMPLXREP)/influence_pipeline.cmx 
	$(LINE) $(COMPLXREP)/influence_pipeline.cmx -o $(BIN)/bd_influence_map

toplevel: $(MLI) $(CMI) $(LIBSC_CMA) $(LIB_BYTE)
	ocaml -I +threads $(OCAMLINCLUDES) $(CMA) $(OBJS)

toplx: $(MLI) $(CMI) $(LIBSC_CMA) $(LIB_BYTE)
	ocamlmktop -o toplx -custom $(OCAMLINCLUDES) -cclib -lunix -cclib -lnums thread.cma unix.cma nums.cma $(LIB_BYTE)

./$(SIMPLXREP)/src/bnf/kappa_parse.ml ./$(SIMPLXREP)/src/bnf/kappa_parse.mli : ./$(SIMPLXREP)/src/bnf/kappa_parse.mly
	ocamlyacc ./$(SIMPLXREP)/src/bnf/kappa_parse.mly 

./$(SIMPLXREP)/src/bnf/kappa_parse.cmo: ./$(SIMPLXREP)/src/bnf/kappa_parse.mli ./$(SIMPLXREP)/src/bnf/kappa_parse.ml
	$(OCAMLC) $(OCAMLFLAGS) -c ./$(SIMPLXREP)/src/bnf/kappa_parse.mli ./$(SIMPLXREP)/src/bnf/kappa_parse.ml

./$(SIMPLXREP)/src/bnf/kappa_lex.ml: ./$(SIMPLXREP)/src/bnf/kappa_lex.mll
	ocamllex ./$(SIMPLXREP)/src/bnf/kappa_lex.mll

./$(COMPLXREP)/backend/parse_comment/yacc.ml: ./$(COMPLXREP)/backend/parse_comment ./$(COMPLXREP)/backend/parse_comment/yacc.mly 
	ocamlyacc ./$(COMPLXREP)/backend/parse_comment/yacc.mly

./$(COMPLXREP)/backend/parse_comment/yacc.cmx: ./$(COMPLXREP)/backend/parse_comment/yacc.cmi ./$(COMPLXREP)/backend/parse_comment/yacc.ml ./$(COMPLXREP)/backend/parse_comment/yacc.mly
	$(OCAMLOPT) -c $(OCAMLFLAGS) ./$(COMPLXREP)/backend/parse_comment/yacc.ml

./$(COMPLXREP)/backend/parse_comment/yacc.cmo: ./$(COMPLXREP)/backend/parse_comment/yacc.cmi ./$(COMPLXREP)/backend/parse_comment/yacc.ml ./$(COMPLXREP)/backend/parse_comment/yacc.mly
	$(OCAMLC) -c $(OCAMLFLAGS) ./$(COMPLXREP)/backend/parse_comment/yacc.ml


./$(COMPLXREP)/backend/parse_comment/yacc.cmi: ./$(COMPLXREP)/backend/parse_comment/yacc.mli2
	cp ./$(COMPLXREP)/backend/parse_comment/yacc.mli2 ./$(COMPLXREP)/backend/parse_comment/yacc.mli;
	ocamlopt -c $(OCAMLFLAGS) ./$(COMPLXREP)/backend/parse_comment/yacc.mli

./$(COMPLXREP)/backend/parse_comment/lexeur.ml: ./$(COMPLXREP)/backend/parse_comment/lexeur.mll
	ocamllex ./$(COMPLXREP)/backend/parse_comment/lexeur.mll

%.cmi : %.mli
	$(OCAMLC) $(OCAMLFLAGS) $<

%.cmo : %.ml 
	$(OCAMLC) $(OCAMLFLAGS) -c $<

%.cmx : %.ml 
	$(OCAMLOPT) $(OCAMLFLAGS) -c $<

install: bin/simplx bin/complx
	sudo ln -sf $(PWD)/bin/* $(INSTALL_DIR) 

install_in_local: bin/simplx bin/complx 
	 ln -sf $(PWD)/bin/* $(LOCAL_DIR) 

uninstall_of_local: clean
	cd $(LOCAL_DIR) ; rm -f complx simplx 

uninstall: clean
	cd $(INSTALL_DIR) ; sudo rm -f complx simplx bd_influence_map

$(HOME)/tmp: 
	mkdir $(HOME)/tmp 

tar:tar_prorep
tar_prorep: $(HOME)/tmp
	make clean_all 
	rm -rf $(HOME)/tmp/ProRepPlx-$(VERSION)
	mkdir $(HOME)/tmp/ProRepPlx-$(VERSION)
	cp -r * $(HOME)/tmp/ProRepPlx-$(VERSION)/
	cd $(HOME)/tmp ; tar czf ProRepPlx-$(VERSION).tgz ProRepPlx-$(VERSION)/*
	cp $(HOME)/tmp/ProRepPlx-$(VERSION).tgz $(HOME)/
	rm $(HOME)/tmp/ProRepPlx-$(VERSION).tgz 



install_light:
	cd simplx_rep ; make install
	cd complx_rep ; make install_light


clean:
	rm -f *~ ; 
	cd $(SIMPLXREP) ; make -f cleanup ;
	cd $(COMPLXREP) ; make -f cleanup ; 
	cd $(INTERPLXREP) ; make -f cleanup

clean_all: clean 
	rm -rf bin 
	rm -f simplx_rep/sim complx_rep/compress complx_rep/compress_light  simplx complx_light bd_influence_map bd_influence_map_light complx *.options* 


help: 
	echo Usage: ;\
	echo make all: create the simulator sim and the compressor compress ;\
	echo make sim: create the simulator ;\
	echo make complx_full: create the compressor;\
	echo make complx_light: create the light version of the compressor without labltk;\
	echo make VERSION=X.YY tar: create all tarballs in your home directory
	echo make VERSION=X.YY tar_sim: create the tarball of simplx in your home directory
	echo make VERSION=X.YY tar_com: create the tarball of complx in your home directory
	echo make VERSION=X.YY tar_prorep: create the tarball of ProRepPlx in your home directory
	echo make clean: clean compiled files;\
	echo make clean_data: clean analysis results;\
	echo make clean_all: clean all