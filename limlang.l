%{
typedef struct astnode astnode_t;

struct arr_info{
  int *arr;
  int size;
};

struct arr_par{
 char **arr_par;
 int size;
};

struct fnc_info{
 struct arr_par *arr_par;
 astnode_t *fnc_loc;
};

struct mat3_info{
 float **arr;
 int size;
};

typedef struct fnc_info fnc_info_t;
typedef struct nr_info nr_info_t;
typedef struct arr_info arr_info_t;
typedef struct arr_par arr_par_t;
typedef struct mat3_info mat3_info_t;
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include "limlang.tab.h"
char *str_1;
int num_1;
void addstr(char);
int octalToDecimal(int);
int rand_counter;
int arr_counter;
int initial = 1;
int arr_index = 0;
int num_index = 0;
%}
%option noyywrap noinput nounput yylineno

DIGIT -?[0-9]+
CHAR [a-zA-Z]+
HEXADECIMAL ([1-9a-fA-F][0-9a-fA-F]*|0)
HEXSTART "#"
HEXEND "#"
OCTSTART "$"
OCTEND "$"
FUNC "function_call"
INT "numb"
INT_ARR "[numb]"
HEX "hex"
POINT "point"
MAT3 "mat3x3"
DECI -?[0-9]+[.][0-9]+

%x STRING COMMENT HEXCOND OCTACOND CASECOND RANDCOND ARR ACCESSARR_COND GLOBAL FUNC_COND PAR CALL_FNC INT_COND INT_ARR_COND POINT_COND MATRIX_COND

%%
"if_"        { return _if; }
"else"      { return _else; }
"loop_"      { return loop; }
"function"  { return _function; }
"call"	    { return call; }
"print"	    { return print; }
"true"	    { yylval.nr = 1; return bool_val; }
"false"	    { yylval.nr = 0; return bool_val; }
"getint"    { return getint; }
"=="     { return equalCompare; }
"global"    { return global; }
"return"    { return _return; }
"add_"	    { return add; }
"in"	    { return _in; }
"%d"	    { return d_int; }
"%x"	    { return h_hex; }
"%o"	    { return o_octa; }
"num"	    { return type_num; }
"[num]"	    { return type_num_arr; }
"point"	    { return type_point;  }	
"shape"     { return type_shape;  }
"->"        { return to; }
"getPoints" { return getPointsInShape; }
"!="	    { return doesNotEqual; }


{DECI}					{ printf("deci : %f\n",atof(yytext)); exit(0); }

{MAT3}					{ BEGIN(MATRIX_COND);	return type_mat3x3;	  }
<MATRIX_COND>{CHAR}			{ yylval.str = strdup(yytext); return id; }
<MATRIX_COND>{DECI}			{ yylval.mat3_info->arr[arr_index][num_index] = atof(yytext); num_index++; }
<MATRIX_COND>";"			{ num_index = 0; arr_index = 0; BEGIN(INITIAL); return mat3_info;        }
<MATRIX_COND>(\t|\n|\ )	 
<MATRIX_COND>"["		
<MATRIX_COND>"]"			{ num_index = 0; arr_index++; }
<MATRIX_COND>","			
<MATRIX_COND>"="			{ yylval.mat3_info = malloc(sizeof(mat3_info)); 
					  yylval.mat3_info->arr = malloc(sizeof(float*)*3);
					  yylval.mat3_info->arr[0] = malloc(sizeof(float)*3);
					  yylval.mat3_info->arr[1] = malloc(sizeof(float)*3);
					  yylval.mat3_info->arr[2] = malloc(sizeof(float)*3);
					  return *yytext;}
<MATRIX_COND>.			

{INT}                     { BEGIN(INT_COND); }
<INT_COND>{CHAR}          { yylval.str = strdup(yytext); printf("id is %s\n", yylval.str); return id; }
<INT_COND>{DIGIT}         { yylval.nr = atoi(yytext); return num; }
<INT_COND>";"             { BEGIN(INITIAL); return *yytext; }
<INT_COND>"="             { return *yytext; }
<INT_COND>(\t|\n|\ ) 		
<INT_COND>.		  { return *yytext; }

{INT_ARR}		  { BEGIN(INT_ARR_COND); }
<INT_ARR_COND>{CHAR}	  { yylval.str = strdup(yytext); return id; }
<INT_ARR_COND>"="	  { return *yytext; } 
<INT_ARR_COND>"["	  { yylval.arr_info_list = malloc(sizeof(arr_info_t)); yylval.arr_info_list->arr = malloc(sizeof(int)); yylval.arr_info_list->size = 0; }
<INT_ARR_COND>{DIGIT}	  { yylval.arr_info_list->arr[yylval.arr_info_list->size] = atoi(yytext);
                  	    yylval.arr_info_list->size++;
                  	    yylval.arr_info_list->arr = realloc( yylval.arr_info_list->arr, (yylval.arr_info_list->size + 1) * sizeof(int)); }
<INT_ARR_COND>"]"	  { BEGIN(INITIAL); return arr_var; }
<INT_ARR_COND>.			

{HEX}                   	{ BEGIN(HEXCOND); if(str_1==NULL){ str_1 = malloc(1); }; *str_1 = '\0'; }
<HEXCOND>{CHAR}         	{ yylval.str = strdup(yytext); return id; }
<HEXCOND>"="            	{ return *yytext;                                       }
<HEXCOND>"#"{HEXADECIMAL}"#"  	{ yytext++; while(*yytext != '#'){addstr(*yytext); yytext++; }  yylval.nr = strtol(str_1,NULL,16); return num; }
<HEXCOND>";"                    { BEGIN(INITIAL); return *yytext; }
<HEXCOND>.

{CHAR}"("	  { BEGIN(CALL_FNC); char *index = strchr(yytext,'(');  yylval.str = strndup(yytext,index-yytext); return id; }	
<CALL_FNC>{CHAR}  {    if(initial){
				initial = 0;
			  	yylval.arr_par = malloc(sizeof(arr_par_t));
                        	yylval.arr_par->size = 0;
                        	yylval.arr_par->arr_par = malloc(sizeof(char *));
			}
			yylval.arr_par->arr_par[yylval.arr_par->size] = strdup(yytext);  yylval.arr_par->size = yylval.arr_par->size + 1; yylval.arr_par->arr_par = realloc(yylval.arr_par->arr_par, sizeof(char *)*yylval.arr_par->size + 1); }
<CALL_FNC>")"	  { BEGIN(INITIAL); initial = 1; return arrPar; }
<CALL_FNC>.  

"function_call"   { BEGIN(FUNC_COND); return _function; }
<FUNC_COND>{CHAR} { yylval.str = strdup(yytext); return id; }
<FUNC_COND>"("	  { BEGIN(PAR);  yylval.arr_par = malloc(sizeof(arr_par_t)); yylval.arr_par->size = 0; yylval.arr_par->arr_par = malloc(sizeof(char *));}
<FUNC_COND>.	  

<PAR>{INT}	  { }
<PAR>{CHAR}	  { yylval.arr_par->arr_par[yylval.arr_par->size] = strdup(yytext);   yylval.arr_par->size = yylval.arr_par->size + 1; yylval.arr_par->arr_par = realloc(yylval.arr_par->arr_par, sizeof(char *)*yylval.arr_par->size + 1);}
<PAR>")"	  { BEGIN(INITIAL); return arrPar; }
<PAR>.		  

{CHAR}"["   { BEGIN(ACCESSARR_COND); char *index = strchr(yytext,'['); yylval.str = strndup(yytext,index-yytext);/* printf("yylval.str: %s\n",yylval.str); */ return accessArr; }
<ACCESSARR_COND>{DIGIT} { yylval.nr = atoi(yytext); return num; }
<ACCESSARR_COND>{CHAR}  { yylval.str =	strdup(yytext); return id; }
<ACCESSARR_COND>"]"     { BEGIN(INITIAL); }
<ACCESSARR_COND>.

"["	    	{ BEGIN(ARR);  yylval.arr_info_list = malloc(sizeof(arr_info_t)); yylval.arr_info_list->arr = malloc(sizeof(int)); yylval.arr_info_list->size = 0; }
<ARR>{DIGIT}	{ yylval.arr_info_list->arr[yylval.arr_info_list->size] = atoi(yytext);
                  yylval.arr_info_list->size++;
		  yylval.arr_info_list->arr = realloc( yylval.arr_info_list->arr, (yylval.arr_info_list->size + 1) * sizeof(int));}
<ARR>"]"	{ BEGIN(INITIAL); return arr_var; }
<ARR>.			

"switch_"   { return _switch; }
"case"	   { BEGIN(CASECOND); return _case; }
<CASECOND>{DIGIT}  { yylval.nr = atoi(yytext); BEGIN(INITIAL); return case_op;}
<CASECOND>.	   { }

"getrand_"  		{ BEGIN(RANDCOND); yylval.arr_info_list = malloc(sizeof(arr_info_t)); yylval.arr_info_list->arr = malloc(sizeof(int)); yylval.arr_info_list->size = 0; }
<RANDCOND>{DIGIT}	{ yylval.arr_info_list->arr[yylval.arr_info_list->size] = atoi(yytext);
                   	  yylval.arr_info_list->size++;
                  	  yylval.arr_info_list->arr = realloc( yylval.arr_info_list->arr, (yylval.arr_info_list->size + 1) * sizeof(int));} 
<RANDCOND>")"		{ BEGIN(INITIAL); return rand_par;}
<RANDCOND>.          

{DIGIT}    { yylval.nr = atoi(yytext); return num; }

{HEXSTART}  { BEGIN(HEXCOND); if(str_1==NULL){ str_1 = malloc(1); }; *str_1 = '\0'; }
{OCTSTART}  { BEGIN(OCTACOND); if(str_1==NULL){ str_1 = malloc(1); }; *str_1 = '\0'; }
{CHAR} 	    { yylval.str = strdup(yytext); return id; }

"\""            { BEGIN(STRING); if(str_1==NULL){ str_1 = malloc(1); }; *str_1 = '\0';}
<STRING>[^"]    { addstr(*yytext); }
<STRING>"\"\""  { addstr('"');  }
<STRING>"/z"    { addstr('\n');}
<STRING>"\""    { BEGIN(INITIAL); yylval.str = strdup(str_1); return str; }
<STRING>"//"    { addstr('/');}

(\t|\n|\ )

"/C"            { BEGIN(COMMENT); }
<COMMENT>.      {}
<COMMENT>"C/"   { BEGIN(INITIAL); }

<OCTACOND>[0-7]+      { num_1 = atoi(yytext);}
<OCTACOND>"!"         { BEGIN(INITIAL); yylval.nr = octalToDecimal(num_1); return num;}

. {  return *yytext; }

%%

void addstr(char ch){
        int l = strlen(str_1);
        str_1 = realloc(str_1,l+2);
        str_1[l] = ch;
        str_1[l+1] = '\0';
}

int octalToDecimal(int octalNumber) {
    int decimalNumber = 0, i = 0, remainder;

    while (octalNumber != 0) {
        remainder = octalNumber % 10;
        octalNumber /= 10;
        decimalNumber += remainder * pow(8, i);
        ++i;
    }

    return decimalNumber;
}
