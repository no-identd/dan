module lang::dan::Syntax

extend lang::std::Layout;

keyword Reserved = "abstract" | "struct" | "choice" | "u8" | "u16" | "u32" | "u64" | "int" | "str" | "bool" | "typ" | "module" | "import";

start syntax Program =
	"module" Id
	Import* imports
	TopLevelDecl* declarations;

lexical Id =  ([a-z A-Z 0-9 _] !<< [a-z A-Z][a-z A-Z 0-9 _]* !>> [a-z A-Z 0-9 _])\Reserved;

lexical DId = Id | "_";

syntax Import
	= "import" Id
	;
	
syntax TopLevelDecl
	= "struct" Id Formals? Annos? "{" DeclInStruct* declarations "}"
	| "choice" Id Formals? Annos? "{" DeclInChoice* declarations "}"
	| Type Id Formals? 
	;
	
syntax Annos 
	= "@" "(" {Anno "," }* annos ")"
	;	
	
syntax Anno
	= Id "=" Expr 
	;	
	
syntax Formals
	= "(" {Formal "," }* formals  ")"
	;
	
syntax Formal = Type typ Id id;
	
syntax Arguments
	= "(" {Expr ","}* args  ")"
	;
	
syntax Size
	= "[" Expr expr "]"
	;	
		
syntax SideCondition 
	= "?" "(" Expr ")"
	| "?" "(" UnaryExpr ")"
	;
	
	
syntax DeclInStruct
	= Type DId Arguments? Size? SideCondition? 
	| Type Id "=" Expr
	;
	
	
syntax Expr 
	= NatLiteral
	| HexIntegerLiteral
	| StringLiteral
	| Id
	| bracket "(" Expr ")"
	| Expr "." Id
	> "-" Expr
	> Expr UnaryOperator Expr
	> Expr "++" Expr
	> Expr "*" Expr
	> Expr "+" Expr
	| Expr "-" Expr
	> Id Arguments
	> Expr "[" Range "]"
	;
		
syntax UnaryOperator 
	= "==" 
	| "!="
	| "\<="
	| "\<"
	| "\>="
	| "\>"
	;   	
	
syntax UnaryExpr
	= UnaryOperator Expr e
	;  
	
syntax Range 
	 = ":" Expr
	 | Expr (":" Expr?)?
	 ;
	
syntax DeclInChoice
	= "abstract" Type Id
	| Type Arguments? Size?
	;

syntax AnonStruct
	= "struct" "{" DeclInStruct* declarations "}"
	;
	
syntax Type
	= Id
	| "int"
	| "str"
	| "bool"
	| "typ"
	| UInt
	| AnonStruct
	| Type "[" "]"
	;
	
lexical UInt = "u" [0-9]+ !>> [0-9];
	
lexical NatLiteral
	=  @category="Constant" [0-9]+ !>> [0-9]
	;

lexical HexIntegerLiteral
	=  [0] [X x] [0-9 A-F a-f]+ !>> [0-9 A-Z _ a-z] ;
	
lexical StringLiteral
	= @category="Constant" "\"" StringCharacter* chars "\"" ;	
	
lexical StringCharacter
	= "\\" [\" \' \< \> \\ b f n r t] 
	| UnicodeEscape 
	| ![\" \' \< \> \\]
	| [\n][\ \t \u00A0 \u1680 \u2000-\u200A \u202F \u205F \u3000]* [\'] // margin 
	;
	
lexical UnicodeEscape
	= utf16: "\\" [u] [0-9 A-F a-f] [0-9 A-F a-f] [0-9 A-F a-f] [0-9 A-F a-f] 
    | utf32: "\\" [U] (("0" [0-9 A-F a-f]) | "10") [0-9 A-F a-f] [0-9 A-F a-f] [0-9 A-F a-f] [0-9 A-F a-f] // 24 bits 
    | ascii: "\\" [a] [0-7] [0-9A-Fa-f]
    ;


