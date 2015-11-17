	# Chi
	Simple syntax for C.
	(Now optimised for proportional fonts.)
	Parser needs parseFnInput, parseFnOutput, parseFnCondition,
	parseType, parseGlobalVar, parseComment, parseCommentBlock, parseRawCode,
	porting to C, text-range library and testing.
	Tuples: Since need to have special treatment anyway, could test differently, i.e. Tuple.OK?
	The other alternative is malloc and free. Stack is preferred for this, I think.

# parse-Chi
» Code [text-range]
« Parsed-block [dict]

Code.parseBlock-Chi:
	» Parsed-block
	» Discarded-tail [text-range]

# parseBlock-Chi
» Code [text-range]
? Code.word(1) == "#"
« Parsed-tree [dict]
« Remaining-code [text-range]

o Block.fromWord(2).parseFn-Chi:
_o Block.fromWord(2).parseType-Chi:_
_o Block.fromWord(2).parseGlobalVar-Chi:_
	» Parsed-tree
	» Tail [text-range]

Tail.parseBlock-Chi:
	» Parsed-tree
	» Remaining-code

# parseFn-Chi
» Code [text-range]
_? Code.word(1) != "["_
? Code.line(1).wordCount() == 1
« Parsed-tree [dict]
« Remaining-code [text-range]

Code.fromLine(2).parseFnBody-Chi:
	» Tree-node [dict]
	» Remaining-code

Tree-node.dictItem("fn")
	.addText: Code.word(1), "name"
	» Parsed-tree

# parseFnBody-Chi
» Code [text-range]
? Code.word(1) != "#"
« Parsed-tree [dict]
« Remaining-code [text-range] = Code

o Code.parseFnInput-Chi:
o Code.parseFnOutput-Chi:
o Code.parseFnCondition-Chi:
o Code.parseBooleanList-Chi:
o Code.parseSingleStatement-Chi:
	» Parsed-tree
	» Tail [text-range]

Tail.parseFnBody-Chi:
	» Parsed-tree
	» Remaining-code

# parseSingleStatement-Chi
» Code [text-range]
« Parsed-tree [dict]
« Remaining-code [text-range]

Code.parseExpression-Chi:
	» Parsed-tree
	» Tail [text-range]

Code.parseOutput-Chi:
	» Parsed-tree
	» Remaining-code

# parseExpression-Chi
» Code [text-range]
« Parsed-tree [dict]
« Remaining-code [text-range]

Code.parseChain-Chi:
	» Parsed-tree
	» Tail [text-range]

Code.parseInfixOperator-Chi:
	» Parsed-tree
	» Remaining-code

# parseChain-Chi
» Code [text-range]
« Parsed-tree [dict]
« Remaining-code [text-range]

o Code.parseFnCall-Chi:
o Code.parseVar-Chi:
o Code.parseNum-Chi:
o Code.parseQuote-Chi:
	» Parsed-tree
	» Tail [text-range]

* Tail.word(1) == "."
* Tail.fromWord(2).parseChain-Chi:
	» Tree-node [dict]
	» Remaining-code

Tree-node.dictItem: "chained"
	» Parsed-tree

# parseFnCall-Chi
» Code [text-range]
? Code.word(2) == "(" or ":"
« Parsed-tree [dict]
« Remaining-code [text-range]

Code.fromWord(2).parseFnParam-Chi:
	» Tree-node [dict]
	» Tail [text-range]

Tree-node.dictItem: "fn-call"
	.addText: Code.word(1), "name"
	» Parsed-tree

* Code.word(2) == "("
* Tail.word(1) == ")"
* Tail.fromWord(2)
o Tail
	» Remaining-code

# parseFnParam-Chi
» Code [text-range]
? Code.word(1) == "(" or ":" or ","
« Parsed-tree [dict]
« Remaining-code [text-range] = Code

Code.fromWord(2).parseExpression-Chi:
	» Parsed-tree
	» Tail [text-range]

Tail.parseFnParam-Chi
	» Parsed-tree
	» Remaining-code

# parseVar-Chi
» Code [text-range]
? Code.wordType(1) == WordTypeWord
« Parsed-tree [dict]
« Remaining-code [text-range]

Code.word(1).dictItem("var")
	.addText: Code.word(1), "name"
	» Parsed-tree
Code.fromWord(2)
	» Remaining-code

# parseNum-Chi
» Code [text-range]
? Code.wordType(1) == NumTypeWord
« Parsed-tree [dict]
« Remaining-code [text-range]

Code.word(1).dictItem("num")
	.addText: Code.word(1), "val"
	» Parsed-tree
Code.fromWord(2)
	» Remaining-code

# parseVar-Chi
» Code [text-range]
? Code.wordType(1) == QuoteTypeWord
« Parsed-tree [dict]
« Remaining-code [text-range]

Code.word(1).dictItem("quote")
	.addText: Code.word(1), "text"
	» Parsed-tree
Code.fromWord(2)
	» Remaining-code

# parseInfixOperator-Chi
» Code [text-range]
? Code.word(1) == "+" or "-" or "÷" or "×" or "or" or "==" or "!=" or "<" or ">" or "≤" or "≥"
« Parsed-tree [dict]
« Remaining-code [text-range]

Code.word(1).textItem: "operator"
	» Parsed-tree
Code.fromWord(2).parseExpression:
	» Parsed-tree
	» Remaining-code

# parseBooleanList-Chi
» Code [text-range]
? Code.word(1) == "*" or "o"
« Parsed-tree [dict]
« Remaining-code [text-range]

Code.parseBooleanListItem-Chi:
	» Parsed-tree
	» Tail [text-range]

Tail.parseOutput-Chi:
	» Parsed-tree
	» Remaining-code

# parseBooleanListItem-Chi
» Code [text-range]
? Code.word(1) == "*" or "o"
« Parsed-tree [dict]
« Remaining-code [text-range]

Code.fromWord(2).parseExpression:
	» Tree-node [dict]
	» Tail [text-range]

Tree-node.dictItem: Code.word(1)
	» Parsed-tree

Tail.parseBooleanListItem-Chi:
	» Parsed-tree
	» Remaining-code
