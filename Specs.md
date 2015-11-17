# Chi
- fnDef
	- fnInput
	- fnOuput
	- fnCondition
	- booleanList
	- singleStatement
	- output
	- expr
	- infixOp
	- chain
	- var
	- num
	- quote
	- fnCall
	- fnParam
- type-def
	- alias
	- struct
- global-var
	- dictDef
- op-def
	- output-def

# text-range
- line
- fromLine
- word
- fromWord
- wordType

# dict
- tempDict
- permDict
- delDict
- dictItem
- textItem
- vecItem
- addItem
- addInPlace
- addText
- addVec
- vecIndices [int,int→vec]
- joinDict
- joinText
- joinVec
- forEach [dict,[item,dict→],dict]
- replaceEach [dict,[item,dict→item],dict]
	D.replaceEach: fn, Context
	D.replaceEach: [A,Context→B] Context.find(A) » B
- filterEach [dict,[item,dict→bool],dict]
- reduceEach [dict,[item,item,dict→item],dict]
- inOrder [dict,[item,dict→],dict]