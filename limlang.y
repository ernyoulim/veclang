%{
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
extern int yylineno;
void yyerror(const char *s){
	printf("Parse error in line %d: %s\n",yylineno,s);
}
int yylex(void);
extern FILE *yyin;
enum {
        STMTS = 10000
};

typedef enum {
 GLOBAL
}scope_t;

#define MAXCHILDREN 5
struct arr_info{
  int *arr;
  int size;
};

struct arr_par{
 char **arr_par;
 int size;
};

struct mat3_info{
 float **arr;
 int size;
};

struct nr_info {
 int nr;
 scope_t scope;
};

typedef struct arr_info arr_info_t;
typedef struct arr_par  arr_par_t;
typedef struct mat3_info mat3_info_t;

struct fnc_info;

struct point {
 float x;
 float y;
 float z;
};

typedef struct point point_t;

struct shape {
 int size;
 point_t **points;
};

typedef struct shape shape_t;

struct astnode{
 int type;
 union {
  int num;
  char *str;
  arr_info_t *arr_info_list;
  struct fnc_info *fnc_info;
  arr_par_t *arr_par_list;
  point_t *point;
  shape_t *shape;
  mat3_info_t *mat3_info;
 }val;
 struct astnode *child[MAXCHILDREN];
};

typedef struct astnode astnode_t;


struct fnc_info {
 arr_par_t *arr_par;
 astnode_t *fnc_loc;
};

typedef struct fnc_info fnc_info_t;

struct vec3{
 float x;
 float y; 
 float z;
}; 

astnode_t *createNode0(int type){
        astnode_t *node = calloc(sizeof *node,1);
        node->type = type;
        return node;
}

astnode_t *createNode1(int type, astnode_t *c1){
        astnode_t *node = calloc(sizeof *node,1);
        node->type = type;
        node->child[0] = c1;
        return node;
}

astnode_t *createNode2(int type, astnode_t *c1,astnode_t *c2){
        astnode_t *node = calloc(sizeof *node,1);
        node->type = type;
        node->child[0] = c1;
        node->child[1] = c2;
        return node;
}

astnode_t *createNode3(int type, astnode_t *c1,astnode_t *c2, astnode_t *c3){
        astnode_t *node = calloc(sizeof *node,1);
        node->type = type;
        node->child[0] = c1;
        node->child[1] = c2;
        node->child[2] = c3;
        return node;
}

astnode_t *execute_ast(astnode_t *);

typedef struct {
 char *id;
 int *arr_nr;
 int size;
} arr_t;

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>

typedef enum {
	INT,
	ARR,
	FUNC,
	POINT,
	SHAPE,
	MAT3
} data_type;

typedef struct {
	data_type type;
	union{
		int nr;
        	arr_info_t *arr_info;
		fnc_info_t *fnc_info;
		point_t *point;
		shape_t *shape;
		mat3_info_t *mat3_info;
	}v;
}data_t;

data_t var_declare_global (char *id, data_t val);
data_t var_declare (char *id, data_t val);
data_t var_set (char *id, data_t val);
data_t var_get (char *id);
void var_enter_block (void);
void var_leave_block (void);
void var_enter_function (void);
void var_leave_function (void);
void var_dump (void);

typedef struct {
  char *id;
  data_t val;
  int flags;
} stackval_t;

typedef struct {
  stackval_t *vals;
  int size;
} stack_t;

static stack_t vars, globals;

void s_push (stack_t *stack, stackval_t val) {
  stack->vals = realloc(stack->vals, (stack->size + 1) * sizeof (stackval_t));
  assert(stack->vals != NULL);
  stack->vals[stack->size++] = val;
}

#define VAR_BORDER_FUNC 2
#define VAR_BORDER_BLOCK 1

static stackval_t *var_lookup (char *id, int border) {
  for (int i = vars.size-1; i >= 0; i--) {
    if (vars.vals[i].flags >= border)
      break;
    if (strcmp(vars.vals[i].id, id) == 0)
      return &vars.vals[i];
  }

  if (border == VAR_BORDER_BLOCK)
    return NULL;

  for (int i = globals.size-1; i >= 0; i--) {
    if (strcmp(globals.vals[i].id, id) == 0)
      return &globals.vals[i];
  }

  return NULL;
}

data_t var_declare_global (char *id, data_t val) {
  stackval_t *s = var_lookup (id, 0);
  if (s) {
    // Handle multiple declaration in same block
    // Here: Just ignore the new declaration, set new value
    s->val = val;
  } else {
    s_push(&globals, (stackval_t) { .val = val, .id = strdup(id) });
  }

  return val;
}

data_t var_declare (char *id,data_t val) {
  stackval_t *s = var_lookup (id, VAR_BORDER_BLOCK);
  if (s) {
    // Handle multiple declaration in same block
    // Here: Just ignore the new declaration, set new value
    s->val = val;
  } else {
    s_push(&vars, (stackval_t) { .val = val, .id = strdup(id) });
  }

  return val;
}

data_t var_set (char *id,data_t val) {
  stackval_t *s = var_lookup (id, VAR_BORDER_FUNC);
  if (s)
    s->val = val;
  else {
    // Handle usage of undeclared variable
    // Here: implicitly declare variable
    
    var_declare(id,val);
  }

  return val;
}

data_t var_get (char *id) {
  stackval_t *s = var_lookup (id, VAR_BORDER_FUNC);
  if (s)
    return s->val;
  else {
    // Handle usage of undeclared variable
    // Here: implicitly declare variable
    printf("Declare variable %s before using\n",id);
    exit(0);
    data_t *d = malloc(sizeof(data_t));
    d->type = INT;
    d->v.nr = 0;
    var_declare(id, *d);
    return *d;
  }
}

void var_enter_block (void) {
  s_push(&vars, (stackval_t) { .flags = VAR_BORDER_BLOCK, .id = "" });
}

void var_leave_block (void) {
  int i;
  for (i = vars.size-1; i >= 0; i--) {
    if (vars.vals[i].flags == VAR_BORDER_BLOCK)
      break;
  }
  vars.size = i;
}

void var_enter_function (void) {
  s_push(&vars, (stackval_t) { .flags = VAR_BORDER_FUNC, .id = "" });
}

void var_leave_function (void) {
  int i;
  for (i = vars.size-1; i >= 0; i--) {
    if (vars.vals[i].flags == VAR_BORDER_FUNC)
      break;
  }
  vars.size = i;
}

void var_dump (void) {
  printf("-- TOP --\n");
  for (int i = vars.size-1; i >= 0; i--) {
    if (vars.vals[i].flags == VAR_BORDER_FUNC) {
      printf("FUNCTION\n");
    } else if (vars.vals[i].flags == VAR_BORDER_BLOCK) {
      printf("BLOCK\n");
    } else {
      printf("%s : %d\n", vars.vals[i].id, vars.vals[i].val.v.nr);
    }
  }
  printf("-- BOTTOM --\n");
  for (int i = globals.size-1; i >= 0; i--) {
      printf("%s : %d (global)\n", globals.vals[i].id, globals.vals[i].val.v.nr);
  }
  printf("-- GLOBALS --\n\n");
}
%}

%define parse.error verbose

%union {
 long  nr;
 char *str;
 arr_info_t *arr_info_list;
 astnode_t *ast; 
 arr_par_t *arr_par;
 mat3_info_t *mat3_info;
}

%type <ast> STMTS TERM BLOCK STR ID _CASE NUM FORMAT POINT TYPE

%token <nr>  num
       <str> id
       <str> str
       <nr>  bool_val
       <nr>  case_op
       <arr_info_list> rand_par
       <arr_info_list> arr_var
       <str> accessArr
       <arr_par> arrPar	
       <mat3_info> mat3_info

%token global _if _else print loop _function call getint doesNotEqual equalCompare _switch _case add assignArr _return _in d_int o_octa h_hex print_format point3 type_num type_num_arr type_point type_shape type_mat3x3 firstDeclare accessPoint assignPoint getPointsInShape assignPointInShape shape 

%precedence print
%right '='
%left '&' '|'
%left equalCompare doesNotEqual
%left '<' '>'
%left '+' '-' to
%left '*' '/' '%'
%right '^' '!'


%%

S: STMTS	{ execute_ast($1); }

STMTS: STMTS TERM ';'   { $$ = createNode2(STMTS,$1,$2); }
     | %empty           { $$ = 0; }

TERM : TERM equalCompare TERM { $$ = createNode2(equalCompare,$1,$3); }
     | global ID '=' TERM { $$ = createNode2(global,$2,$4); }
     | TYPE ID '=' TERM      { $$ = createNode3(firstDeclare,$1,$2,$4); }
     | ID '=' TERM 	{ $$ = createNode2('=',$1,$3); }
     | ID doesNotEqual TERM  { $$ = createNode2(doesNotEqual,$1,$3); }
     | TERM '+' TERM    { $$ = createNode2('+',$1,$3); }
     | TERM '-' TERM    { $$ = createNode2('-',$1,$3); }
     | TERM '*' TERM    { $$ = createNode2('*',$1,$3); }
     | TERM '/' TERM    { $$ = createNode2('/',$1,$3); }
     | TERM '<' TERM    { $$ = createNode2('<', $1,$3);  }
     | TERM '>' TERM    { $$ = createNode2('>', $1,$3);  }
     | TERM '%' TERM 	{ $$ = createNode2('%', $1,$3); }  
     | TERM to TERM 	{ $$ = createNode2(to,$1,$3); }
     | print STR        { $$ = createNode1(print,$2); }
     | print TERM       { $$ = createNode1(print,$2); }
     | FORMAT _in print TERM  	{ $$ = createNode2(print_format,$1,$4);}
     | _if '('TERM ')' BLOCK _else BLOCK        { $$ = createNode3(_if,$3,$5,$7); }
     | loop '(' TERM ')' BLOCK                  { $$ = createNode2(loop,$3,$5);   }
     | ID
     | NUM
     /* | _function ID BLOCK { $$ = createNode2(_function, $2, $3); $$->val.fnc_loc = $$; } */
     | _function ID  arrPar  BLOCK { $$=createNode2(_function,$2,$4); $$->val.fnc_info = malloc(sizeof(fnc_info_t)); $$->val.fnc_info->fnc_loc = $$;  $$->val.fnc_info->arr_par = $3; }
     | call '(' ID ')' 	{ $$ = createNode1(call,$3); }
     | TERM '|' TERM 	{ $$ = createNode2('|',$1, $3); }
     | '!' TERM      	{ $$ = createNode1('!',$2);    }
     | TERM '&' TERM 	{ $$ = createNode2('&',$1,$3); }
     | bool_val 	{ $$ = createNode0(bool_val); $$->val.num = $1; }
     | getint		{ $$ = createNode0(getint); }
     | _switch '(' TERM ')' '{' _CASE '}' { $$ = createNode2(_switch,$3,$6); }
     | rand_par		{ $$ = createNode0(rand_par); $$->val.arr_info_list = $1; }
     | arr_var		{ $$ = createNode0(arr_var); $$->val.arr_info_list = $1; }
     | accessArr NUM '=' TERM	{ $$ = createNode2(assignArr,$2,$4); $$->val.str = $1;  }
     | accessArr NUM    { $$ = createNode1(accessArr,$2); $$->val.str = $1; }
     | accessArr ID '=' TERM {  $$ = createNode2(assignArr,$2,$4); $$->val.str = $1; }
     | accessArr ID	{ $$ = createNode1(accessArr,$2); $$->val.str = $1; }
     | ID '@' ID	{ $$ = createNode2(accessPoint,$1,$3);}
     | ID '@' ID '=' TERM 			{ $$ = createNode3(assignPoint,$1,$3,$5); } 
     | ID '.' getPointsInShape '<'TERM'>'	{ $$ = createNode2(getPointsInShape,$1,$5);}
     | ID '.' getPointsInShape '<'TERM'>''=' TERM  { $$ = createNode3(assignPointInShape,$1,$5,$8); }
     | ID '[' NUM ']'   { $$ = createNode2(accessArr,$1,$3);}
     | ID '[' ID  ']'   { $$ = createNode2(accessArr,$1,$3);} 
     | ID '.' add '(' TERM ')' { $$ = createNode2(add,$1,$5); } 
     | ID arrPar 	{ $$ = createNode1(call,$1);  $$->val.arr_par_list = $2; }     
     | _return		{ $$ = createNode0(_return); }
     | POINT			        
     | mat3_info		{ $$ = createNode0(mat3_info); $$->val.mat3_info = $1; }

_CASE: _case case_op ':' STMTS _CASE  	{ $$ = createNode2(_case,$4,$5); $$->val.num = $2; }  	 
     | %empty				{ $$ = 0; }

FORMAT: d_int				{ $$ = createNode0(d_int); }
      | o_octa				{ $$ = createNode0(o_octa); }
      | h_hex				{ $$ = createNode0(h_hex); }

ID: id                  {  $$ = createNode0(id); $$->val.str = $1;}

NUM: num		{  $$ = createNode0(num); $$->val.num = $1; }

BLOCK: '{' STMTS '}'    { $$ = $2; }

STR: str                { $$ = createNode0(str); $$->val.str = $1;}

TYPE: type_num		{ $$ = createNode0(type_num);		  }
    | type_num_arr	{ $$ = createNode0(type_num_arr);	  } 
    | type_point	{ $$ = createNode0(type_point);		  } 
    | type_shape	{ $$ = createNode0(type_shape);		  }
    | type_mat3x3	{ $$ = createNode0(type_mat3x3);	  } 

POINT: '(' NUM ',' NUM ',' NUM ')'	{ $$ = createNode3(point3,$2,$4,$6); }

%%

void matrixMultiplication(float **mat1, float  mat2[], float result[]) {
    int i, j;
 
    for (i = 0; i < 3; i++) {
        result[i] = 0;
        for (j = 0; j < 3; j++) {
            result[i] += mat1[j][i] * mat2[j];
        }
    }
}

int op_case = 0;

int return_fnc = 0;

data_t* getValBeforeEnterFnc(arr_par_t *var){
 int iteration = 0;
 data_t *val = malloc(sizeof(data_t) * var->size);
 
 while(var->size !=  iteration){
        /* printf("var %s\n",var->arr_par[iteration]); */
        data_t d_10 = var_get(var->arr_par[iteration]);
        val[iteration] = d_10;
	/* printf("jest : %d\n",val[iteration]); */
        iteration++;
 }
 return val;
}

void assignValbeforeEnterFnc(arr_par_t *var,data_t *val){
 int iteration = 0;
 while(var->size !=  iteration){
	/* printf("var %s\n",var->arr_par[iteration]);*/
	/* data_t *data = malloc(sizeof(data_t)); */
        /* data->type = INT;*/
        /* data->v.nr = val[iteration]; */
        var_set(var->arr_par[iteration],val[iteration]);
	iteration++;
 }
 /* printf("doneeeeeeeee\n");*/
};

astnode_t* execute_ast(astnode_t *root){
        if(root==NULL){
                return root;
        }
        switch(root->type) {
		case mat3_info:
			return root;		
		case assignPoint:
			data_t pn = var_get(root->child[0]->val.str);
			int kv123 = execute_ast(root->child[2])->val.num;
			char *x_2 = "x";
                        char *y_2 = "y";
                        char *z_2 = "z";
			int diff_1 = strcmp(root->child[1]->val.str,x_2);
                        if(diff_1 == 0){
                        	pn.v.point->x = kv123;
                        }
                        diff_1 = strcmp(root->child[1]->val.str,y_2);
                        if(diff_1 == 0){
                                pn.v.point->y = kv123;
                        }
                        diff_1 = strcmp(root->child[1]->val.str,z_2);
                        if(diff_1 == 0){
                                pn.v.point->z = kv123;
                        }	
			break;
		case assignPointInShape:
			data_t shape_name_1 = var_get(root->child[0]->val.str);
			shape_t *sn1 = shape_name_1.v.shape;
			sn1->points[execute_ast(root->child[1])->val.num] = execute_ast(root->child[2])->val.point;
			break;
		case getPointsInShape:
			data_t shape_name = var_get(root->child[0]->val.str);
			shape_t *sn = shape_name.v.shape;
			astnode_t *n1 = malloc(sizeof(astnode_t));
			n1->val.point = sn->points[execute_ast(root->child[1])->val.num];
			n1->type = point3;
			return n1;
		case to:
			astnode_t *node_gb = malloc(sizeof(astnode_t));
			node_gb->type = type_shape;
			astnode_t *node_2 = execute_ast(root->child[0]);
			astnode_t *node_3 = execute_ast(root->child[1]);
			if(node_2->type == point3){
				node_gb->val.shape = malloc(sizeof(shape_t));
				node_gb->val.shape->size = 2;
				node_gb->val.shape->points = malloc(sizeof(point_t)*2);
				node_gb->val.shape->points[0] = node_2->val.point;
				node_gb->val.shape->points[1] = node_3->val.point;
				return node_gb;
			}else{
				node_gb->val.shape = node_2->val.shape;
				node_gb->val.shape->points = realloc( node_gb->val.shape->points, sizeof(point_t) * node_gb->val.shape->size + 1);
				node_gb->val.shape->points[node_gb->val.shape->size] = node_3->val.point;
				node_gb->val.shape->size = node_gb->val.shape->size + 1;
				return node_gb;
			}
			break;
		case accessPoint:
			data_t d_x = var_get(root->child[0]->val.str);
			astnode_t *nq = malloc(sizeof(astnode_t));
			nq->type = num;
			char *x_1 = "x";
			char *y_1 = "y";
			char *z_1 = "z";
			
			int diff = strcmp(root->child[1]->val.str,x_1);
			if(diff == 0){
				nq->val.num = d_x.v.point->x;
                                return nq;
			}
			diff = strcmp(root->child[1]->val.str,y_1);
			if(diff == 0){
                                nq->val.num = d_x.v.point->y;
                                return nq;
                        } 
			diff = strcmp(root->child[1]->val.str,z_1);
			if(diff == 0){
                                nq->val.num = d_x.v.point->z;
                                return nq;
                        }
			assert(0);
		case firstDeclare:
			char *id_left_1 = root->child[1]->val.str;
                        if(root->child[0]->type == type_num_arr){
                                data_t *data = malloc(sizeof(data_t));
                                data->type = ARR;
                                data->v.arr_info = root->child[2]->val.arr_info_list;
                                var_set(id_left_1,*data);
                                /* var_set(id_left,*data); */
                        }else if (root->child[0]->type == type_num){
                                int result = execute_ast(root->child[2])->val.num;
                                data_t *data = malloc(sizeof(data_t));
                                data->type = INT;
                                data->v.nr = result;
                                /* printf("set %s\n",id_left); */
                                var_set(id_left_1,*data);
                                /* printf("crash %d\n",data_crash.v.nr); */
                                /* var_set(id_left,*data); */
                        }else if(root->child[0]->type == type_point){
				point_t *p = execute_ast(root->child[2])->val.point;
				data_t *data_123 = malloc(sizeof(data_t));
                                data_123->type = POINT;
                                data_123->v.point = p;
                                /* printf("set %s\n",id_left); */
                                var_set(id_left_1,*data_123);			
			}else if(root->child[0]->type == type_shape){
				shape_t * shape = execute_ast(root->child[2])->val.shape;
				data_t *data_1234 = malloc(sizeof(data_t));
                                data_1234->type = SHAPE;
                                data_1234->v.shape = shape;
                                /* printf("set %s\n",id_left); */
                                var_set(id_left_1,*data_1234);
			}else {
				mat3_info_t *mat3_info = execute_ast(root->child[2])->val.mat3_info;		
				data_t *data_mat = malloc(sizeof(data_t));
				data_mat->type = MAT3;
				data_mat->v.mat3_info = mat3_info;
				/* printf("val is %f\n",data_mat->v.mat3_info->arr[2][2]); */
				var_set(id_left_1,*data_mat);
			}
			break;
		case point3:
			point_t * p = malloc(sizeof(point_t));
			p->x = execute_ast(root->child[0])->val.num;
			p->y = execute_ast(root->child[1])->val.num;
			p->z = execute_ast(root->child[2])->val.num;
			root->val.point = p;
			return root;
			break;
		case _return:
			return_fnc = 1;		
			/* printf("hallo\n"); */
			return root;
		case assignArr:
			int arr_index = execute_ast(root->child[0])->val.num;
			int new_val = execute_ast(root->child[1])->val.num;
			data_t d_arr = var_get(root->val.str);
			d_arr.v.arr_info->arr[arr_index] = new_val;
			break;
		case global:
			char *id_left_global  = root->child[0]->val.str;
                        int result = execute_ast(root->child[1])->val.num;
                        data_t *data = malloc(sizeof(data_t));
                        data->type = INT;
                        data->v.nr = result;
                        /* printf("Result :%d\n",result); */
                        var_declare_global(id_left_global,*data);
			break;
		case _function:
			char *func_name = root->child[0]->val.str;
			data_t *data_fnc = malloc(sizeof(data_t));
			/* printf("dsadada\n");*/
			data_fnc->type = FUNC;
			data_fnc->v.fnc_info = malloc(sizeof(fnc_info_t));
			data_fnc->v.fnc_info->fnc_loc = root->child[1];
			data_fnc->v.fnc_info->arr_par = root->val.fnc_info->arr_par;
			var_declare_global(func_name,*data_fnc);
			/* var_set(func_name,*data_fnc); */
			break;
                case STMTS:
			/* printf("root type: %d\n",_return);*/
			execute_ast(root->child[0]); 
			
			if(return_fnc == 1){
				return_fnc = 0;
				/* printf("about to execute return \n");*/
				break;	
                        }
			
			execute_ast(root->child[1]);
			
			if(return_fnc == 1){
				return_fnc = 0;
                                /* printf("about to execute return \n");*/
                                break;
                        }
			break;
                case '+':	
			astnode_t *r = execute_ast(root->child[0]);
			astnode_t *node_return = malloc(sizeof(astnode_t));
			if(r->type == point3){
				root->val.point = malloc(sizeof(point_t));
				point_t *p1 = r->val.point; 
				point_t *p2 = execute_ast(root->child[1])->val.point;
				root->val.point->x = p1->x + p2->x;
				root->val.point->y = p1->y + p2->y;
				root->val.point->z = p1->z + p2->z;
				return root;
			}else if(r->type == num){
				node_return->type = num;
				node_return->val.num = r->val.num + execute_ast(root->child[1])->val.num; return node_return;
			}else{
				shape_t *new_s2 = malloc(sizeof(shape_t));
                                if(r->type == type_shape){;
                                        new_s2->points = malloc(sizeof(point_t*) * r->val.shape->size);
                                        new_s2->size = r->val.shape->size;
                                        point_t *p_test_1 = execute_ast(root->child[1])->val.point;
                                        for(int iter=0; iter< r->val.shape->size; iter++){
                                                point_t *pc1 = r->val.shape->points[iter];
                                                new_s2->points[iter] = malloc(sizeof(point_t));
                                                new_s2->points[iter]->x = pc1->x + p_test_1->x;
                                                new_s2->points[iter]->y = pc1->y + p_test_1->y;
                                                new_s2->points[iter]->z = pc1->z + p_test_1->z;
                                        }
                                        node_return->type = type_shape;
                                        node_return->val.shape = new_s2;
                                        return node_return;
                                }
			}
                case '-':
			astnode_t *r_1 = execute_ast(root->child[0]);
			astnode_t *node_return_1 = malloc(sizeof(astnode_t));
			if(r_1->type == num){
				node_return_1->type = num;
				node_return_1->val.num = r_1->val.num - execute_ast(root->child[1])->val.num; return node_return_1;
			}else if(r_1->type == point3){
                                root->val.point = malloc(sizeof(point_t));
                                point_t *p1 = r_1->val.point;
                                point_t *p2 = execute_ast(root->child[1])->val.point;
                                root->val.point->x = p1->x - p2->x;
                                root->val.point->y = p1->y - p2->y;
                                root->val.point->z = p1->z - p2->z;
                                return root;
                        }else{	
                              	shape_t *new_s1 = malloc(sizeof(shape_t));
                                if(r_1->type == type_shape){;
                                        new_s1->points = malloc(sizeof(point_t*) * r_1->val.shape->size);
                                        new_s1->size = r_1->val.shape->size;
               				point_t *p_test = execute_ast(root->child[1])->val.point;
                                        for(int iter=0; iter< r_1->val.shape->size; iter++){
                                                point_t *pc = r_1->val.shape->points[iter];
						new_s1->points[iter] = malloc(sizeof(point_t));
						new_s1->points[iter]->x = pc->x - p_test->x;
						new_s1->points[iter]->y = pc->y - p_test->y;
						new_s1->points[iter]->z = pc->z - p_test->z;
                                        }
					node_return_1->type = type_shape;  	
                             		node_return_1->val.shape = new_s1;
                                        return node_return_1;
                                }
                        }
                case '*':
			astnode_t *r_2 = execute_ast(root->child[0]);
			astnode_t *t_2 = execute_ast(root->child[1]);
			astnode_t *node_t = malloc(sizeof(astnode_t));
			float x_co;float y_co; float z_co; float matrix3[3]; float result_mat[3];
			if(r_2->type == num){
				astnode_t *root_num = malloc(sizeof(astnode_t));
				root_num->type = num;
				root_num->val.num = r_2->val.num * t_2->val.num; return root_num;
			}else if(r_2->type == point3 || t_2->type == point3){
				mat3_info_t *mat3_info_x;
				if(r_2->type == point3){
					mat3_info_x = t_2->val.mat3_info;
					x_co = r_2->val.point->x; 
					y_co = r_2->val.point->y;
					z_co = r_2->val.point->z;
					matrix3[0] = x_co; matrix3[1] = y_co; matrix3[2] = z_co;
					matrixMultiplication(mat3_info_x->arr,matrix3,result_mat);
					/* printf("result is %f",result_mat[1]);*/	
					point_t *vec = malloc(sizeof(point_t));
					vec->x = result_mat[0]; vec->y = result_mat[1]; vec->z = result_mat[2];
					root->val.point = vec;
					return root;
				}else{
					mat3_info_x = r_2->val.mat3_info;
					x_co = t_2->val.point->x;
					y_co = t_2->val.point->y;
					z_co = t_2->val.point->z;
                                        matrix3[0] = x_co; matrix3[1] = y_co; matrix3[2] = z_co;
                                        matrixMultiplication(mat3_info_x->arr,matrix3,result_mat);	
					point_t *vec_1 = malloc(sizeof(point_t));
                                        vec_1->x = result_mat[0]; vec_1->y = result_mat[1]; vec_1->z = result_mat[2];
                                        root->val.point = vec_1;
                                        return root;
				}
			}else{	
				mat3_info_t *mat3_info_shape;
				shape_t *new_s = malloc(sizeof(shape_t));
				if(r_2->type == type_shape){
                                	new_s->points = malloc(sizeof(point_t*) * r_2->val.shape->size);
                                	new_s->size = r_2->val.shape->size;
					mat3_info_shape = t_2->val.mat3_info;
					for(int iter=0; iter< r_2->val.shape->size; iter++){
						point_t *pc = r_2->val.shape->points[iter];
						x_co = pc->x;
                                        	y_co = pc->y;
                                        	z_co = pc->z;
                                        	matrix3[0] = x_co; matrix3[1] = y_co; matrix3[2] = z_co;
						matrixMultiplication(mat3_info_shape->arr,matrix3,result_mat);
						new_s->points[iter] = malloc(sizeof(point_t));
						new_s->points[iter]->x = result_mat[0];
						new_s->points[iter]->y = result_mat[1];
						new_s->points[iter]->z = result_mat[2];	 
					}
					node_t->val.shape = new_s;
					node_t->type = type_shape;
					return node_t;
				}
			}
                case '/':
			astnode_t *root_divide = malloc(sizeof(astnode_t));
                        root_divide->type = num;
                        root_divide->val.num = execute_ast(root->child[0])->val.num / execute_ast(root->child[1])->val.num; return root_divide;
                case '=':
                        char *id_left = root->child[0]->val.str; 
			data_t foundData = var_get(id_left);

			if(foundData.type == POINT){
				assert(execute_ast(root->child[1])->type == point3);
				point_t *p_equal = execute_ast(root->child[1])->val.point;
				data_t *data = malloc(sizeof(data_t));
                                data->type = POINT;
                                data->v.point = p_equal;
				var_set(id_left,*data);
				break;
			}
					
			if(foundData.type == ARR){
				assert(root->child[1]->type == ARR);
				data_t *data = malloc(sizeof(data_t));
                                data->type = ARR;
                                data->v.arr_info = root->child[1]->val.arr_info_list;
                                var_set(id_left,*data);
			}else if (foundData.type == INT){ 
				int result = execute_ast(root->child[1])->val.num;
				data_t *data = malloc(sizeof(data_t));
				data->type = INT;
				data->v.nr = result;
				/* printf("set %s\n",id_left); */ 
				var_set(id_left,*data);
				/* printf("crash %d\n",data_crash.v.nr); */
				/* var_set(id_left,*data); */
			}else if (foundData.type == SHAPE){
				assert( execute_ast(root->child[1])->type == type_shape);
				data_t *data = malloc(sizeof(data_t));
                                data->v.shape =  execute_ast(root->child[1])->val.shape;
                                var_set(id_left,*data);
			}	
			return root;
                case num:
                        return root;
                case id:
                      	data_t k  = var_get(root->val.str);astnode_t *node_test = malloc(sizeof(astnode_t)); 
			if(k.type == POINT){
				node_test->type = point3;
				node_test->val.point = k.v.point; return node_test;
			}else if(k.type == INT){
				node_test->type = num;
				node_test->val.num =  k.v.nr; return node_test;
			}else if(k.type == MAT3){
				node_test->type = mat3_info;
				node_test->val.mat3_info = k.v.mat3_info; return node_test;
			}else{
				node_test->type = type_shape;
				node_test->val.shape = k.v.shape; return node_test;
			}
                case print:
                       	if (root->child[0]->type == str)
				printf("> %s\n", root->child[0]->val.str);
			else if ( execute_ast(root->child[0])->type  == num)
				printf("# %d\n", execute_ast(root->child[0])->val.num);
			else if (execute_ast(root->child[0])->type == point3){	
				 point_t *p_print = execute_ast(root->child[0])->val.point;
				 printf("point %s coordinates: x: %f, y: %f, z: %f\n",root->child[0]->val.str,p_print->x,p_print->y,p_print->z);
			}else{
				shape_t *s1 = execute_ast(root->child[0])->val.shape;
				for(int it = 0; it < s1->size; it++){
					printf("point %s coordinates: x: %f, y: %f, z: %f\n",root->child[0]->val.str,s1->points[it]->x,s1->points[it]->y,s1->points[it]->z);
				}
			}
			return root;
		case print_format:
			switch(root->child[0]->type){
				case d_int:
					printf("%d\n",execute_ast(root->child[1])->val.num);
					break;
				case h_hex:
					printf("%x\n",execute_ast(root->child[1])->val.num);
					break;
				case o_octa:
					printf("%o\n",execute_ast(root->child[1])->val.num);
					break;	
			}
			break;
                case '<':
                      	if(execute_ast(root->child[0])->val.num < execute_ast(root->child[1])->val.num ){ root->val.num = 1; return root; }else{  root->val.num = 0; return root; }
                case _if:
                        if(execute_ast(root->child[0])->val.num ){ execute_ast(root->child[1]);} else{ execute_ast(root->child[2]);} return root;
                case loop:
			 int eval = execute_ast(root->child[0])->val.num;
                       	 while(eval == 1){ 
				execute_ast(root->child[1]);
				eval = execute_ast(root->child[0])->val.num;
			 }	 
			return root;
                case call:
			char *fnc_name_1 = root->child[0]->val.str;
			/* printf("fnc_name is %s\n",fnc_name_1); */
			data_t l = var_get(fnc_name_1);
			/* printf("hey man\n"); */
			data_t *assignVal = getValBeforeEnterFnc(root->val.arr_par_list);
			var_enter_function();
			assignValbeforeEnterFnc(l.v.fnc_info->arr_par,assignVal);
			execute_ast(l.v.fnc_info->fnc_loc);
			var_leave_function();
          		return_fnc = 0;
			break;
		case '>':
			if(execute_ast(root->child[0])->val.num > execute_ast(root->child[1])->val.num ){ 
				root->val.num = 1; 
				return root;  
			}else{ 
				root->val.num = 0; 
				return root;  
			}
		case bool_val:
			return root;
		case '&':
			root->val.num = (execute_ast(root->child[0])->val.num && execute_ast(root->child[1])->val.num ); return root;
		case '|':
			root->val.num = (execute_ast(root->child[0])->val.num || execute_ast(root->child[1])->val.num); return root;
		case '!':
			root->val.num = !(execute_ast(root->child[0])->val.num); return root;
		case getint:
			astnode_t *int_node = malloc(sizeof(astnode_t));
			int n = 0; scanf("%d",&n); int_node->val.num = n; int_node->type = num; return int_node;
		case doesNotEqual:
			if (execute_ast(root->child[0])->val.num != execute_ast(root->child[1])->val.num ){
				root->val.num = 1; return root; 
			}else{
				root->val.num = 0; return root;
			}
		case '%':
			root->val.num = execute_ast(root->child[0])->val.num  % execute_ast(root->child[1])->val.num; return root;
		case equalCompare:
			root->val.num = execute_ast(root->child[0])->val.num == execute_ast(root->child[1])->val.num; return root;
		case _switch: 
			op_case = execute_ast(root->child[0])->val.num;
			execute_ast(root->child[1]);
			return root;
		case _case: 
			int current_op = root->val.num;
			if(op_case == current_op){
				execute_ast(root->child[0]);
			}else{
				execute_ast(root->child[1]);
			}
			return root;
		case rand_par:
			int ran = (rand() % (root->val.arr_info_list->arr[1] - root->val.arr_info_list->arr[0] + 1) + root->val.arr_info_list->arr[0]);
			astnode_t *node_int_1 = malloc(sizeof(astnode_t));
			node_int_1->type = num; 
			node_int_1->val.num = ran;
			return node_int_1;
		case accessArr:
			data_t d_1 = var_get(root->val.str);
			astnode_t *node_int_2 = malloc(sizeof(astnode_t));
			node_int_2->val.num = d_1.v.arr_info->arr[execute_ast(root->child[0])->val.num];
			node_int_2->type = num;
			return node_int_2;
			/* val = arr_s_lookup(s,root->val.str); */
			/* return val->arr_nr[execute_ast(root->child[0])]; */
		case add:
			 data_t d = var_get(root->child[0]->val.str);
			 d.v.arr_info->size++;
			 d.v.arr_info->arr = realloc(d.v.arr_info->arr, (d.v.arr_info->size + 1) * sizeof(int));
			 d.v.arr_info->arr[d.v.arr_info->size-1] = execute_ast(root->child[1])->val.num;
			 /* arr_t *id_arr = arr_s_lookup(s,root->child[0]->val.str);*/
			 /* id_arr->size++; */
			 /* id_arr->arr_nr = realloc(id_arr->arr_nr, (id_arr->size) * sizeof(int)) */;
			 /* id_arr->arr_nr[id_arr->size-1] = execute_ast(root->child[1]); */
			 return root; 
	}
	return root;	
}

int main(int argc, char **argv){
	yyin = fopen(argv[1],"r");
	return yyparse();

} 
