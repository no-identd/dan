module lang::dan::Generator

import lang::dan::Syntax;
import lang::dan::Checker;

import List;

extend analysis::typepal::TypePal;

str makeSafeId(str id, loc lo) =
	"<newId>_<lo.offset>_<lo.length>_<lo.begin.line>_<lo.end.line>_<lo.begin.column>_<lo.end.column>"
	when newId := (("<id>"=="_")?"dummy":"<id>");

str compile(current: (Program) `module <Id moduleName> <Import* imports> <TopLevelDecl* decls>`, rel[loc,loc] useDefs, map[loc, AType] types)
	= "import io.parsingdata.metal.expression.value.ValueExpression;
	  'import io.parsingdata.metal.token.Token;
	  '
	  'import static io.parsingdata.metal.Shorthand.EMPTY;
	  'import static io.parsingdata.metal.Shorthand.con;
	  'import static io.parsingdata.metal.Shorthand.seq;
	  'import static io.parsingdata.metal.Shorthand.eq;
	  'import static io.parsingdata.metal.Shorthand.gtEqNum;
	  'import static io.parsingdata.metal.Shorthand.ref;
	  'import static io.parsingdata.metal.Shorthand.rep;
	  'import static io.parsingdata.metal.Shorthand.repn;
	  'import static io.parsingdata.metal.Shorthand.def;
	  ' 
	  'class <safeId> {
	  '\t<intercalate("\n", [compile(d, useDefs, types) | d <-decls])>
	  '}"
	when safeId := makeSafeId("<moduleName>", current@\loc);
 

 
str compile(current:(TopLevelDecl) `struct <Id id> <Formals? formals> <Annos? annos> { <DeclInStruct* decls> }`, rel[loc,loc] useDefs, map[loc, AType] types) =
   "private static final Token <safeId><compiledFormals> <startBlock> <compiledDecls>; <endBlock>"           	
	when safeId := makeSafeId("<id>", current@\loc),
		 areThereFormals := (fls <- formals),
		 startBlock := (areThereFormals?"{ return ":"="),
		 endBlock := (areThereFormals?"}":""),
		 compiledFormals := {if (fs  <- formals) compile(fs, useDefs, types); else "";},
		 declsNumber := (0| it +1 | d <-decls),
		 compiledDecls := ((declsNumber == 0)?"EMPTY":
		 	((declsNumber ==  1)? (([compile(d,useDefs,types) | d <-decls])[0]) : "seq(<intercalate(", ", ["\"<safeId>\""] + [compile(d, useDefs, types) | d <-decls])>)"))
		 ;



str compile(current:(DeclInStruct) `<Type ty>[] <DId id> <Arguments? args> <SideCondition? cond>`, rel[loc,loc] useDefs, map[loc, AType] types) =
	"rep(\"<safeId>\", <compile(ty, useDefs, types)>)"
	when safeId := makeSafeId("<id>", current@\loc);
	
str compile(current:(DeclInStruct) `<Type ty>[] <DId id> <Arguments? args> [<Expr n>] <SideCondition? cond>`, rel[loc,loc] useDefs, map[loc, AType] types) =
	"repn(\"<safeId>\", <compile(ty, useDefs, types)>,  <compile(n, useDefs, types)>)"
	when safeId := makeSafeId("<id>", current@\loc);

str compile(Formals current, rel[loc,loc] useDefs, map[loc, AType] types)
	= "(<intercalate(", ", actualFormals)>)"
	when actualFormals := [compile(af, useDefs, types) | af <- current.formals];
	
str compile(current:(Formal) `<Type ty> <Id id>`, rel[loc,loc] useDefs, map[loc, AType] types)
	= "ValueExpression <safeId>"
	when safeId := makeSafeId("<id>", current@\loc);
	        	
str compile(current:(DeclInStruct) `<Type ty> <DId id> <Arguments? args> <Size? size> <SideCondition? cond>`, rel[loc,loc] useDefs, map[loc, AType] types) =
	"def(\"<safeId>\", <compile(ty, useDefs, types)><compileArgs><compiledCond>)"
	when safeId := makeSafeId("<id>", current@\loc),
		 compileArgs := ("" | it + compile(aargs, useDefs, types) | aargs <- args),
		 compiledCond := ("" | it + ", <compile(c, useDefs, types)>" | c <- cond);   
		 
str compile((Arguments)  `( <{Expr ","}* args>  )`, rel[loc,loc] useDefs, map[loc, AType] types)
	= "(<intercalate(", ", actualArgs)>)"
	when actualArgs := [compile(arg, useDefs, types) | arg <- args];	 
	
str compile(current:(Type)`<UInt v>`, rel[loc,loc] useDefs, map[loc, AType] types) =
	"con(<toInt("<v>"[1..])/4>)";

str compile(current:(Type)`<Id id>`, rel[loc,loc] useDefs, map[loc, AType] types) =
	makeSafeId("<id>", lo)
	when lo := ([l | l <- useDefs[id@\loc]])[0], bprintln("lox: <lo>");
	

str compile(current:(SideCondition) `? ( <Expr e>)`, rel[loc,loc] useDefs, map[loc, AType] types){
	
}

str compile(current:(SideCondition) `while ( <Expr e>)`, rel[loc,loc] useDefs, map[loc, AType] types){
	
}

str compile(current:(SideCondition) `? ( <ComparatorOperator uo> <Expr e>)`, rel[loc,loc] useDefs, map[loc, AType] types)
	= "<compile(uo, useDefs, types)>(<compile(e, useDefs, types)>)";

default str compile(current:(SideCondition) `? ( <UnaryOperator uo> <Expr e>)`, rel[loc,loc] useDefs, map[loc, AType] types)
	= "<compile(uo, useDefs, types)>(<compile(e, useDefs, types)>)";

str compile(current:(ComparatorOperator) `\>=`, rel[loc,loc] useDefs, map[loc, AType] types) = "gtEqNum";

str compile(current:(UnaryOperator) `==`, rel[loc,loc] useDefs, map[loc, AType] types) = "eq";

str compile(current: (Expr) `<StringLiteral lit>`, rel[loc,loc] useDefs, map[loc, AType] types) = "con(<lit>)";

str compile(current: (Expr) `<HexIntegerLiteral nat>`, rel[loc,loc] useDefs, map[loc, AType] types) = "";

str compile(current: (Expr) `<BitLiteral nat>`, rel[loc,loc] useDefs, map[loc, AType] types) = "";

str compile(current: (Expr) `<NatLiteral nat>`, rel[loc,loc] useDefs, map[loc, AType] types) = "con(<nat>)";

str compile(current: (Expr) `<Id id>`, rel[loc,loc] useDefs, map[loc, AType] types) = "ref(\"<makeSafeId("<id>", lo)>\")" 
	when lo := ([l | l <- useDefs[id@\loc]])[0],
		 bprintln("loco: <lo>");
	  
str type2Java(AType t) = "ValueExpression"
	when isTokenType(t);	  
str type2Java(intType()) = "int";
str type2Java(strType()) = "String";
str type2Java(boolType()) = "boolean";
str type2Java(listType(t)) = "List\<<type2Java(t)>\>"
	when !isTokenType(t);	  
            	
/*            	
void collect(current:(TopLevelDecl) `<Type t> <Id id> <Formals? formals>`,  Collector c) {
     actualFormals = [af | fformals <- formals, af <- fformals.formals];
     collect(t, c);
     collect(actualFormals, c);
     c.define("<id>", funId(), current, defType([t] + actualFormals, AType(Solver s) {
     	return funType("<id>", s.getType(t), atypeList([s.getType(a) | a <- actualFormals]));
     	})); 
    
}

void collect(current:(Formal) `<Type ty> <Id id>`, Collector c){
	c.define("<id>", fieldId(), current, defType(ty));
	collect(ty, c);
}

void collect(current:(DeclInStruct) `<Type ty> <Id id> = <Expr expr>`,  Collector c) {
	c.define("<id>", fieldId(), id, defType(ty));
	collect(ty, c);
	collect(expr, c);
	c.require("good assignment", current, [expr],
        void (Solver s) { s.requireSubtype(s.getType(expr), s.getType(ty), error(current, "Expression should be <ty>, found <prettyPrintAType(s.getType(expr))>")); });
}    



void collectSideCondition(Type ty, DId id, current:(SideCondition) `? ( <Expr e>)`, Collector c){
	c.enterScope(current);
	c.define("this", variableId(), id, defType(ty));
	collect(e, c);
	c.require("side condition", current, [e], void (Solver s) {
		s.requireEqual(s.getType(e), boolType(), error(current, "Side condition must be boolean"));
	});
	c.leaveScope(current);
}

void collectSideCondition(Type ty, DId id, current:(SideCondition) `while ( <Expr e>)`, Collector c){
	c.enterScope(current);
	c.define("it", variableId(), id, defType([ty], AType (Solver s) {
		s.requireTrue(listType(t) := s.getType(ty), error(current, "while side condition can only guard list types"));
		listType(t) = s.getType(ty);
		return t;
	}));
	collect(e, c);
	c.leaveScope(current);
	
}

void collectSideCondition(Type _, DId id, current:(SideCondition) `? ( <ComparatorOperator uo> <Expr e>)`, Collector c){
	collect(e, c);
	c.require("side condition", current, [e], void (Solver s) {
		s.requireSubtype(s.getType(e), intType(), error(current, "Expression in unary comparing side condition must have numeric type"));
	});
	//c.requireEqual(ty, e, error(sc, "Unary expression in side condition must have the same type as declaration"));
}

default void collectSideCondition(Type _, DId id, current:(SideCondition) `? ( <UnaryOperator uo> <Expr e>)`, Collector c){
	collect(e, c);
	//c.requireEqual(ty, e, error(sc, "Unary expression in side condition must have the same type as declaration"));
}

void collectSize(Type ty, sz:(Size) `[<Expr e>]`, Collector c){
	collect(e, c);
	c.require("size argument", sz, [ty] + [e], void (Solver s) {
		s.requireTrue(s.getType(ty) is listType, error(sz, "Setting size on a non-list element"));
		s.requireSubtype(s.getType(e), intType(), error(sz, "Size must be an integer"));
	});
}

void collectArgs(Type ty, Arguments? current, Collector c){
		currentScope = c.getScope();
		for (aargs <- current, a <- aargs.args){
			collect(a, c);
		}
		c.require("constructor arguments", current, 
			  [ty] + [a |aargs <- current, a <- aargs.args], void (Solver s) {
			if (aargs <- current && !isUserDefined(s.getType(ty)))
				s.report(error(current, "Constructor arguments only apply to user-defined types but got %t", ty));
			if (isUserDefined(s.getType(ty))){
				idStr = getUserDefinedName(s.getType(ty));
				//ty_ = top-down-break visit (ty){
				//	case (Type)`<Type t> []` => t
				//	case Type t => t
				//};
				//tyLoc = ty@\loc;
				//conId = fixLocation(parse(#Type, "<ty_>"), tyLoc[offset=tyLoc.offset + tyLoc.length]);
				//conId = fixLocation(parse(#Type, "<ty_>"), tyLoc);
				ty_ = getNestedType(ty);
				AType t = s.getType(ty_);
				//println(t);
				//println(conId);
				//println(currentScope);
				ct = s.getTypeInType(t, newConstructorId([Id] "<idStr>"), {consId()}, currentScope);
				argTypes = atypeList([ s.getType(a) | aargs <- current, a <- aargs.args]);
				s.requireSubtype(argTypes, ct.formals, error(current, "Wrong type of arguments"));
			}
		});
	
}

void collectFunctionArgs(Id id, Arguments current, Collector c){
		for (a <- current.args){
			collect(a, c);
		}
		c.require("constructor arguments", current, 
			  [id] + [a | a <- current.args], void (Solver s) {
			ty = s.getType(id);  
			if (!funType(_,_,_) := ty)
				s.report(error(current, "Function arguments only apply to function types but got %t", ty));
			else{
				funType(_, _, formals) = ty;
			    argTypes = atypeList([ s.getType(a) |  a <- current.args]);
				s.requireSubtype(argTypes, formals, error(current, "Wrong type of arguments"));
			}
		});
	
}

void collectFormals(Id id, Formals? current, Collector c){
	actualFormals = [af | fformals <- current, af <- fformals.formals];
	c.define("<newConstructorId(id)>", consId(), id, defType(actualFormals, AType(Solver s) {
     		return consType(atypeList([s.getType(a) | a <- actualFormals]));
    }));
    collect(actualFormals, c);
}

void collect(current:(TopLevelDecl) `choice <Id id> <Formals? formals> <Annos? annos> { <DeclInChoice* decls> }`,  Collector c) {
	 // TODO  explore `Solver.getAllDefinedInType` for implementing the check of abstract fields
	 c.define("<id>", structId(), current, defType(refType("<id>")));
     c.enterScope(current); {
     	collectFormals(id, formals, c);
     	collect(decls, c);
     	ts = for (d <- decls){
     			switch (d){
     				case (DeclInChoice) `abstract <Type ty> <Id _>`: append(ty);
     				case (DeclInChoice) `<Type ty> <Arguments? _> <Size? _>`: append(ty);
     			};
     		};
     	currentScope = c.getScope();
     	c.require("abstract fields", current, [id] + ts, void(Solver s){
     		//ts = for ((DeclInChoice) `<Type ty> <Arguments? args> <Size? size>` <- decls){
     		//	append(s.getType(ty));
     		//};
     		rel[str id,AType ty] abstractFields = s.getAllDefinedInType(refType("<id>"), currentScope, {fieldId()});
     		for (actualFormals <- formals, formal <- actualFormals.formals)
     			abstractFields = {f | f <-abstractFields, f.id != "<formal.id>"};
     		 for ((DeclInChoice) `<Type ty> <Arguments? args> <Size? size>` <- decls){
     			//set[str id, AType ty] fsConcrete = //s.getAllDefinedInType(s.getType(ty), currentScope, {fieldId()});
     			for (f <- abstractFields){
     				try{
     					AType t = s.getTypeInType(s.getType(ty), [Id] "<f.id>", { fieldId() }, currentScope);
     				}catch _:{
     					s.report(error(ty, "Missing implementation of abstract field")); 
     				};
     				
     			};
     			
     		};
     			
     	});
    }
    c.leaveScope(current);
    
}

void collect(current:(DeclInChoice) `abstract <Type ty> <Id id>`,  Collector c) {
	c.define("<id>", fieldId(), id, defType(ty));
	collect(ty, c);
}

void collect(current:(DeclInChoice) `<Type ty> <Arguments? args> <Size? size>`,  Collector c) {
	c.require("declared type", ty, [ty], void(Solver s){
		s.requireTrue(isTokenType(s.getType(ty)), error(ty, "Non-initialized fields must be of a token type but it was %t", ty));
	});
	collect(ty, c);
	collectArgs(ty, args, c);
	
	for (sz <-size){
		collectSize(ty, sz, c);
	}
}

void collect(current:(UnaryExpr) `<UnaryOperator uo> <Expr e>`, Collector c){
	collect(e, c);
}


void collect(current:(Type)`<UInt v>`, Collector c) {
	c.fact(current, uType(toInt("<v>"[1..])));
}

void collect(current:(Type)`<SInt v>`, Collector c) {
	c.fact(current, sType(toInt("<v>"[1..])));
}

void collect(current:(Type)`str`, Collector c) {
	c.fact(current, strType());
}

void collect(current:(Type)`bool`, Collector c) {
	c.fact(current, boolType());
}  

void collect(current:(Type)`typ`, Collector c) {
	c.fact(current, typeType());
}  

void collect(current:(Type)`int`, Collector c) {
	c.fact(current, intType());
}  

void collect(current:(Type)`<Id i>`, Collector c) {
	c.use(i, {structId()}); 
} 

void collect(current:(Type)`struct { <DeclInStruct* decls>}`, Collector c) {
	c.enterScope(current);
		collect(decls, c);
	c.leaveScope(current);
	fields =for (d <-decls){
			switch(d){
				case (DeclInStruct) `<Type t> <Id id> = <Expr e>`: append(<"<id>", t>);
				case (DeclInStruct) `<Type t> <DId id> <Arguments? args> <Size? size> <SideCondition? sc>`: append(<"<id>", t>);
			};
		};
	//for (<id, ty> <- fields){
	//		c.define("<id>", fieldId(), current, defType(ty));
	//};
	c.calculate("anonymous struct type", current, [ty | <_, ty> <- fields], AType(Solver s){
		return anonType([<id, s.getType(ty)> | <id, ty> <- fields]);
	});
} 

void collect(current:(TopLevelDecl) `struct <Id id> <Formals? formals> <Annos? annos> { <DeclInStruct* decls> }`,  Collector c) {
     c.define("<id>", structId(), current, defType(refType("<id>")));
     //collect(id, formals, c);
     c.enterScope(current); {
     	actualFormals = [af | f <- formals, af <- f.formals];
     	c.define("<id>", consId(), id, defType(actualFormals, AType(Solver s) {
     		return consType(atypeList([s.getType(a) | a <- actualFormals]));
     	}));
     	collect(actualFormals, c);
     	
     	collect(decls, c);
    }
    c.leaveScope(current);
}

void collect(current:(Type)`<Type t> [ ]`, Collector c) {
	collect(t, c);
	c.calculate("list type", current, [t], AType(Solver s) { return listType(s.getType(t)); });
}  

void collect(current: (Expr) `[<{Expr ","}*  exprs>]`, Collector c){
    collect([e | e <-exprs], c);
    c.calculate("list type", current, [e | e <-exprs], AType(Solver s) { 
    	return (listType(voidType()) | lub(it, listType(x)) | x <- [s.getType(e) | e <- exprs ]);
     });
}



void collect(current: (Expr) `<StringLiteral lit>`, Collector c){
    c.fact(current, strType());
}

void collect(current: (Expr) `<HexIntegerLiteral nat>`, Collector c){
    c.fact(current, intType());
}

void collect(current: (Expr) `<BitLiteral nat>`, Collector c){
    c.fact(current, intType());
}

void collect(current: (Expr) `<NatLiteral nat>`, Collector c){
    c.fact(current, intType());
}

void collect(current: (Expr) `<Id id>`, Collector c){
    c.use(id, {variableId(), fieldId()});
}

void collect(current: (Expr) `<Expr e>.offset`, Collector c){
	collect(e, c);
	c.require("offset", current, [e], void (Solver s) {
		s.requireTrue(isTokenType(s.getType(e)), error(current, "Only token types have offsets"));
	}); 
	c.fact(current, intType());
}

void collect(current: (Expr) `<Expr e>.length`, Collector c){
	collect(e, c);
	c.require("length", current, [e], void (Solver s) {
		s.requireTrue(listType(_) := s.getType(e), error(current, "Only list types have length"));
	}); 
	c.fact(current, intType());
}

void collect(current: (Expr) `<Expr e>.type`, Collector c){
	collect(e, c);
	c.fact(current, typeType());
}

void collect(current: (Expr) `<Expr e>.size`, Collector c){
	collect(e, c);
	c.require("size", current, [e], void (Solver s) {
		s.requireTrue(isTokenType(s.getType(e)), error(current, "Only token types have size"));
	}); 
	c.fact(current, intType());
}

void collect(current: (Expr) `<Expr e>.<Id field>`, Collector c){
	collect(e, c);
	//currentScope = c.getScope();
	c.useViaType(e, field, {fieldId()});
	c.fact(current, field);
	//c.calculate("field type", current, [e], AType(Solver s) {
	//	return s.getTypeInType(s.getType(e), field, {fieldId()}, currentScope); });

}

void collect(current: (Expr) `<Id id> <Arguments args>`, Collector c){
	c.use(id, {funId()});
	collectFunctionArgs(id, args, c);
	c.calculate("function call", current, [id] + [a | a <- args.args], AType(Solver s){
		ty = s.getType(id);
		if (!funType(_, _, _) := ty)
				s.report(error(current, "Function arguments only apply to function types but got %t", ty));
		else{
			funType(_, retType, _) = ty;
			return retType;
			
		}
	});	
}


void collect(current: (Expr) `<Expr e>[<Range r>]`, Collector c){
	collect(e, c);
	c.require("list expression", current, [e], void(Solver s){
			s.requireTrue(listType(_) := s.getType(e), error(e, "Expression must be of list type"));
		});
	collectRange(current, e, r, c);
}

void collectRange(Expr access, Expr e, current:(Range) `: <Expr end>`, Collector c){
	collect(end, c);
	c.calculate("list access", access, [e, end], AType (Solver s){
		s.requireSubtype(end, intType(), error(end, "Index must be integer"));
		return s.getType(e);
	});
}

void collectRange(Expr access, Expr e, current:(Range) `<Expr begin> : <Expr end>`, Collector c){
	collect(begin, end, c);
	c.calculate("list access", access, [e, begin, end], AType (Solver s){
		s.requireEqual(begin, intType(), error(begin, "Index must be integer"));
		s.requireEqual(end, intType(), error(end, "Index must be integer"));
		return s.getType(e);
	});
}

void collectRange(Expr access, Expr e, current: (Range) `<Expr begin> :`, Collector c){
	collect(begin, c);
	c.calculate("list access", access, [e, begin], AType (Solver s){
		s.requireEqual(begin, intType(), error(begin, "Index must be integer"));
		return s.getType(e);
	});
}
	
void collectRange(Expr access, Expr e, current: (Range) `<Expr idx>`, Collector c){
	collect(idx, c);
	c.calculate("list access", access, [e, idx], AType (Solver s){
		s.requireEqual(idx, intType(), error(idx, "Indexes must be integers"));
		s.requireTrue(listType(ty) := s.getType(e), error(e, "Expression is not of type list"));
		listType(ty) = s.getType(e);
		return ty;
	});	
}

void collect(current: (Expr) `<Expr e1> == <Expr e2>`, Collector c){
    collect(e1, e2, c);
    collectInfixOperation(current, "==", infixEquality, e1, e2, c); 
}

void collect(current: (Expr) `<Expr e1> != <Expr e2>`, Collector c){
    collect(e1, e2, c);
    collectInfixOperation(current, "!=", infixEquality, e1, e2, c); 
}


void collect(current: (Expr) `<Expr e1> || <Expr e2>`, Collector c){
    collect(e1, e2, c);
    collectInfixOperation(current, "||", infixLogical, e1, e2, c); 
}

void collect(current: (Expr) `<Expr e1> && <Expr e2>`, Collector c){
    collect(e1, e2, c);
    collectInfixOperation(current, "&&", infixLogical, e1, e2, c); 
}

void collect(current: (Expr) `<Expr e1> ? <Expr e2> : <Expr e3>`, Collector c){
    collect(e1, e2, e3, c);
    // TODO relax equality requirement
	c.calculate("ternary operator", current, [e1, e2, e3], AType(Solver s) {
		s.requireSubtype(e1, boolType(), error(e1, "Condition must be boolean"));
		s.requireTrue(s.subtype(e2, e3) || s.subtype(e3, e2), error(e2, "The two branches of the ternary operation must have the same type"));
		return s.subtype(e2, e3)?s.getType(e3):s.getType(e2);
	});
}

void collect(current: (Expr) `<Expr e1> <ComparatorOperator u> <Expr e2>`, Collector c){
    collect(e1, e2, c);
    collectInfixOperation(current, "<u>", infixComparator, e1, e2, c); 
}

void collect(current: (Expr) `<Expr e1> & <Expr e2>`, Collector c){
    collect(e1, e2, c);
    collectInfixOperation(current, "&", infixBitwise, e1, e2, c); 
}

void collect(current: (Expr) `<Expr e1> ^ <Expr e2>`, Collector c){
    collect(e1, e2, c);
    collectInfixOperation(current, "^", infixBitwise, e1, e2, c); 
}

void collect(current: (Expr) `<Expr e1> | <Expr e2>`, Collector c){
    collect(e1, e2, c);
    collectInfixOperation(current, "|", infixBitwise, e1, e2, c); 
}


void collect(current: (Expr) `<Expr e1> \>\> <Expr e2>`, Collector c){
    collect(e1, e2, c);
    collectInfixOperation(current, "\>\>", infixShift, e1, e2, c); 
}

void collect(current: (Expr) `<Expr e1> \>\>\> <Expr e2>`, Collector c){
    collect(e1, e2, c);
    collectInfixOperation(current, "\>\>\>", infixShift, e1, e2, c); 
}

void collect(current: (Expr) `<Expr e1> \<\< <Expr e2>`, Collector c){
    collect(e1, e2, c);
    collectInfixOperation(current, "\<\<", infixShift, e1, e2, c); 
}


void collect(current: (Expr) `<Expr e1> + <Expr e2>`, Collector c){
    collect(e1, e2, c);
    collectInfixOperation(current, "+", infixArithmetic, e1, e2, c); 
}

void collect(current: (Expr) `<Expr e1> % <Expr e2>`, Collector c){
    collect(e1, e2, c);
    collectInfixOperation(current, "%", infixArithmetic, e1, e2, c); 
}

void collect(current: (Expr) `<Expr e1> / <Expr e2>`, Collector c){
    collect(e1, e2, c);
    collectInfixOperation(current, "/", infixArithmetic, e1, e2, c); 
}

void collect(current: (Expr) `<Expr e1> - <Expr e2>`, Collector c){
    collect(e1, e2, c);
    collectInfixOperation(current, "-", infixArithmetic, e1, e2, c); 
}

void collect(current: (Expr) `<Expr e1> * <Expr e2>`, Collector c){
    collect(e1, e2, c);
    collectInfixOperation(current, "*", infixArithmetic, e1, e2, c); 
}

void collect(current: (Expr) `<Expr e1> ++ <Expr e2>`, Collector c){
    collect(e1, e2, c);
    collectInfixOperation(current, "++", infixConcat, e1, e2, c); 
}

void collect(current: (Expr) `(<Expr e>)`, Collector c){
    collect(e, c); 
    // TODO is this really necessary
    c.calculate("parenthesized expression", current, [e], AType(Solver s){ return s.getType(e); });
}

void collectInfixOperation(Tree current, str op, AType (AType,AType) infixFun, Tree lhs, Tree rhs, Collector c) {
	c.calculate("<op>",current, [lhs, rhs], AType(Solver s) {
		try{
			return infixFun(s.getType(lhs), s.getType(rhs));
		}	
		catch str msg:{
			s.report(error(current, msg));
		}
	});
}	

// ----  Examples & Tests --------------------------------
TModel danTModelFromTree(Tree pt, bool debug = false){
    if (pt has top) pt = pt.top;
    c = newCollector("collectAndSolve", pt, config=getDanConfig(), debug=debug);    // TODO get more meaningfull name
    collect(pt, c);
    handleImports(c, pt, pathConfig(pt@\loc));
    return newSolver(pt, c.run(), debug=debug).run();
}

tuple[bool isNamedType, str typeName, set[IdRole] idRoles] danGetTypeNameAndRole(refType(str name)) = <true, name, {structId()}>;
tuple[bool isNamedType, str typeName, set[IdRole] idRoles] danGetTypeNameAndRole(funType(str name, _, _)) = <true, name, {funId()}>;
tuple[bool isNamedType, str typeName, set[IdRole] idRoles] danGetTypeNameAndRole(AType t) = <false, "", {}>;

AType danGetTypeInAnonymousStruct(AType containerType, Tree selector, loc scope, Solver s){
    if(anonType(fields) :=  containerType){
    	return Set::getOneFrom((ListRelation::index(fields))["<selector>"]);
    }
    else
    {	s.report(error(selector, "Undefined field <selector> on %t",containerType));
    }
}

private TypePalConfig getDanConfig() = tconfig(
    isSubType = isConvertible,
    getTypeNameAndRole = danGetTypeNameAndRole,
    getTypeInNamelessType = danGetTypeInAnonymousStruct
);

*/
public start[Program] sampleDan(str name) = parse(#start[Program], |project://dan-core/<name>.dan|);

str compileDan(str name) {
    start[Program] pt = sampleDan(name);
    TModel model = danTModelFromTree(pt);
    map[loc, AType] types = getFacts(model);
    rel[loc, loc] useDefs = getUseDef(model);
    return compile(pt.top, useDefs, types);
}