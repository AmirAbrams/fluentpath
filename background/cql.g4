grammar cql;

import fluentpath;

/*
 * Parser Rules
 */

library
    :
    libraryDefinition?
    usingDefinition*
	includeDefinition*
	codesystemDefinition*
	valuesetDefinition*
	parameterDefinition*
	statement+
	;

/*
 * Definitions
 */

libraryDefinition
    : 'library' identifier ('version' versionSpecifier)?
    ;

usingDefinition
    : 'using' identifier ('version' versionSpecifier)?
    ;

includeDefinition
    : 'include' identifier ('version' versionSpecifier)? 'called' localIdentifier
    ;

localIdentifier
    : identifier
    ;

accessModifier
    : 'public'
    | 'private'
    ;

parameterDefinition
    : accessModifier? 'parameter' identifier (typeSpecifier)? ('default' expression)?
    ;

codesystemDefinition
    : accessModifier? 'codesystem' identifier ':' codesystemId ('version' versionSpecifier)?
    ;

valuesetDefinition
    : accessModifier? 'valueset' identifier ':' valuesetId ('version' versionSpecifier)? codesystems?
    ;

codesystems
    : 'codesystems' '(' codesystemIdentifier (',' codesystemIdentifier)* ')'
    ;

codesystemIdentifier
    : (libraryIdentifier '.')? identifier
    ;

libraryIdentifier
    : identifier
    ;

codesystemId
    : STRING
    ;

valuesetId
    : STRING
    ;

versionSpecifier
    : STRING
    ;

/*
 * Type Specifiers
 */

typeSpecifier
    : namedTypeSpecifier
    | listTypeSpecifier
    | intervalTypeSpecifier
    | tupleTypeSpecifier
    ;

namedTypeSpecifier
    : (modelIdentifier '.')? identifier
    ;

modelIdentifier
    : identifier
    ;

listTypeSpecifier
    : 'List' '<' typeSpecifier '>'
    ;

intervalTypeSpecifier
    : 'Interval' '<' typeSpecifier '>'
    ;

tupleTypeSpecifier
    : 'Tuple' '{' tupleElementDefinition (',' tupleElementDefinition)* '}'
    ;

tupleElementDefinition
    : identifier typeSpecifier
    ;

/*
 * Statements
 */

statement
    : expressionDefinition
    | contextDefinition
    | functionDefinition
    ;

expressionDefinition
    : 'define' accessModifier? identifier ':' expression
    ;

contextDefinition
    : 'context' identifier
    ;

functionDefinition
    : 'define' accessModifier? 'function' identifier '(' (operandDefinition (',' operandDefinition)*)? ')' ':' functionBody
    ;

operandDefinition
    : identifier typeSpecifier
    ;

functionBody
    : expression
    ;

/*
 * Expressions
 */

querySource
    : retrieve
    | qualifiedIdentifier
    | '(' expression ')'
    ;

aliasedQuerySource
    : querySource alias
    ;

alias
    : identifier
    ;

queryInclusionClause
    : withClause
    | withoutClause
    ;

withClause
    : 'with' aliasedQuerySource 'such that' expression
    ;

withoutClause
    : 'without' aliasedQuerySource 'such that' expression
    ;

retrieve
    : '[' namedTypeSpecifier (':' (valuesetPathIdentifier 'in')? valueset)? ']'
    ;

valuesetPathIdentifier
    : identifier
    ;

valueset
    : qualifiedIdentifier
    ;

qualifier
    : identifier
    ;

query
    : sourceClause letClause? queryInclusionClause* whereClause? returnClause? sortClause?
    ;

sourceClause
    : singleSourceClause
    | multipleSourceClause
    ;

singleSourceClause
    : aliasedQuerySource
    ;

multipleSourceClause
    : 'from' aliasedQuerySource (',' aliasedQuerySource)*
    ;

letClause
    : 'let' letClauseItem (',' letClauseItem)*
    ;

letClauseItem
    : identifier ':' expression
    ;

whereClause
    : 'where' expression
    ;

returnClause
    : 'return' ('all' | 'distinct')? expression
    ;

sortClause
    : 'sort' ( sortDirection | ('by' sortByItem (',' sortByItem)*) )
    ;

sortDirection
    : 'asc' | 'ascending'
    | 'desc' | 'descending'
    ;

sortByItem
    : expressionTerm sortDirection?
    ;

qualifiedIdentifier
    : (qualifier '.')* identifier
    ;

expression
    : expressionTerm                                                                                #termExpression
    | retrieve                                                                                      #retrieveExpression
    | query                                                                                         #queryExpression
    | expression 'is' 'not'? ('null' | 'true' | 'false')                                            #booleanExpression
    | expression ('is' | 'as') typeSpecifier                                                        #typeExpression
    | 'cast' expression 'as' typeSpecifier                                                          #castExpression
    | 'not' expression                                                                              #notExpression
    | 'exists' expression                                                                           #existenceExpression
    | expression 'properly'? 'between' expressionTerm 'and' expressionTerm                          #betweenExpression
    | pluralDateTimePrecision 'between' expressionTerm 'and' expressionTerm                         #durationBetweenExpression
    | 'difference' 'in' pluralDateTimePrecision 'between' expressionTerm 'and' expressionTerm       #differenceBetweenExpression
    | expression ('<=' | '<' | '>' | '>=') expression                                               #inequalityExpression
    | expression intervalOperatorPhrase expression                                                  #timingExpression
    | expression ('=' | '<>' | '!=' | '~' | '!~') expression                                        #equalityExpression
    | expression ('in' | 'contains') dateTimePrecisionSpecifier? expression                         #membershipExpression
    | expression 'and' expression                                                                   #andExpression
    | expression ('or' | 'xor') expression                                                          #orExpression
    | expression 'implies' expression                                                               #impliesExpression
    | expression ('|' | 'union' | 'intersect' | 'except') expression                                #inFixSetExpression
    ;

dateTimePrecision
    : 'year' | 'month' | 'week' | 'day' | 'hour' | 'minute' | 'second' | 'millisecond'
    ;

dateTimeComponent
    : dateTimePrecision
    | 'date'
    | 'time'
    | 'timezone'
    ;

pluralDateTimePrecision
    : 'years' | 'months' | 'weeks' | 'days' | 'hours' | 'minutes' | 'seconds' | 'milliseconds'
    ;

expressionTerm
    : term                                                               #termExpressionTerm
    | expressionTerm '.' invocation                                      #invocationExpressionTerm
    | expressionTerm '[' expression ']'                                  #indexedExpressionTerm
    | 'convert' expression 'to' typeSpecifier                            #conversionExpressionTerm
    | ('+' | '-') expressionTerm                                         #polarityExpressionTerm
    | ('start' | 'end') 'of' expressionTerm                              #timeBoundaryExpressionTerm
    | dateTimeComponent 'from' expressionTerm                            #timeUnitExpressionTerm
    | 'duration' 'in' pluralDateTimePrecision 'of' expressionTerm        #durationExpressionTerm
    | 'width' 'of' expressionTerm                                        #widthExpressionTerm
    | 'successor' 'of' expressionTerm                                    #successorExpressionTerm
    | 'predecessor' 'of' expressionTerm                                  #predecessorExpressionTerm
    | 'singleton' 'from' expressionTerm                                  #elementExtractorExpressionTerm
    | ('minimum' | 'maximum') namedTypeSpecifier                         #typeExtentExpressionTerm
    | expressionTerm '^' expressionTerm                                  #powerExpressionTerm
    | expressionTerm ('*' | '/' | 'div' | 'mod') expressionTerm          #multiplicationExpressionTerm
    | expressionTerm ('+' | '-') expressionTerm                          #additionExpressionTerm
    | 'if' expression 'then' expression 'else' expression                #ifThenElseExpressionTerm
    | 'case' expression? caseExpressionItem+ 'else' expression 'end'     #caseExpressionTerm
    | ('distinct' | 'collapse' | 'flatten') expression                   #aggregateExpressionTerm
    ;

caseExpressionItem
    : 'when' expression 'then' expression
    ;

dateTimePrecisionSpecifier
    : dateTimePrecision 'of'
    ;

relativeQualifier
    : 'or before'
    | 'or after'
    ;

offsetRelativeQualifier
    : 'or more'
    | 'or less'
    ;

quantityOffset
    : quantity offsetRelativeQualifier?
    ;

intervalOperatorPhrase
    : ('starts' | 'ends' | 'occurs')? 'same' dateTimePrecision? (relativeQualifier | 'as') ('start' | 'end')?               #concurrentWithIntervalOperatorPhrase
    | 'properly'? 'includes' dateTimePrecisionSpecifier? ('start' | 'end')?                                                 #includesIntervalOperatorPhrase
    | ('starts' | 'ends' | 'occurs')? 'properly'? ('during' | 'included in') dateTimePrecisionSpecifier?                    #includedInIntervalOperatorPhrase
    | ('starts' | 'ends' | 'occurs')? quantityOffset? ('before' | 'after') dateTimePrecisionSpecifier? ('start' | 'end')?   #beforeOrAfterIntervalOperatorPhrase
    | ('starts' | 'ends' | 'occurs')? 'properly'? 'within' quantity 'of' ('start' | 'end')?                                 #withinIntervalOperatorPhrase
    | 'meets' ('before' | 'after')? dateTimePrecisionSpecifier?                                                             #meetsIntervalOperatorPhrase
    | 'overlaps' ('before' | 'after')? dateTimePrecisionSpecifier?                                                          #overlapsIntervalOperatorPhrase
    | 'starts' dateTimePrecisionSpecifier?                                                                                  #startsIntervalOperatorPhrase
    | 'ends' dateTimePrecisionSpecifier?                                                                                    #endsIntervalOperatorPhrase
    ;

term
    : invocation            #invocationTerm
    | literal               #literalTerm
    | externalConstant      #externalConstantTerm
    | intervalSelector      #intervalSelectorTerm
    | tupleSelector         #tupleSelectorTerm
    | instanceSelector      #instanceSelectorTerm
    | listSelector          #listSelectorTerm
    | codeSelector          #codeSelectorTerm
    | conceptSelector       #conceptSelectorTerm
    | '(' expression ')'    #parenthesizedTerm
    ;

literal
        : ('true' | 'false')                                    #booleanLiteral
        | 'null'                                                #nullLiteral
        | STRING                                                #stringLiteral
        | NUMBER                                                #numberLiteral
        | DATETIME                                              #dateTimeLiteral
        | TIME                                                  #timeLiteral
        | quantity                                              #quantityLiteral
        ;

intervalSelector
    : // TODO: Consider this as an alternative syntax for intervals... (would need to be moved up to expression to make it work)
    //expression ( '..' | '*.' | '.*' | '**' ) expression;
    'Interval' ('['|'(') expression ',' expression (']'|')')
    ;

tupleSelector
    : 'Tuple'? '{' (':' | (tupleElementSelector (',' tupleElementSelector)*)) '}'
    ;

tupleElementSelector
    : identifier ':' expression
    ;

instanceSelector
    : namedTypeSpecifier '{' (':' | (instanceElementSelector (',' instanceElementSelector)*)) '}'
    ;

instanceElementSelector
    : identifier ':' expression
    ;

listSelector
    : ('List' ('<' typeSpecifier '>')?)? '{' (expression (',' expression)*)? '}'
    ;

displayClause
    : 'display' STRING
    ;

codeSelector
    : 'Code' STRING 'from' codesystemIdentifier displayClause?
    ;

conceptSelector
    : 'Concept' '{' codeSelector (',' codeSelector)* '}' displayClause?
    ;

identifier
    : IDENTIFIER | QUOTEDIDENTIFIER
    // Include here any keyword that should not be a reserved word
    | 'Code'
    | 'Concept'
    | 'date'
    | 'display'
    | 'time'
    | 'timezone'
    | 'version'
    ;

