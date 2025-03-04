protected package derv.impl

import std.ast.* // cjlint-ignore !G.PKG.01
import std.collection.{ArrayList, ArrayStack, HashMap, ReadOnlyMap}
import std.deriving.Derive

@Derive[ToString]
protected enum SubTerm {
    | Single(Tokens)
    | Qualified(Tokens)
    | SingleCall(Tokens)
    | QualifiedCall(Tokens)
}

protected class Parser {
    let input: Tokens
    var curr = 0
    var start = 0
    var end = 0
    var kind = 0u8 // 0 单identifier， 1 identifier.identifier, 2 idenrifier(...), 3 identifier.identifier(...)
    let arr = ArrayList<SubTerm>()
    
    public init(input: Tokens) {
        this.input = input
    }

    public func parse(): Array<SubTerm> {
        this.exprs()
        arr.toArray()
    }
    
    public func peek(): Token {
        if (curr >= input.size) {
            Token(ILLEGAL)
        } else {
            input[curr]
        }
    }

    public func next(): Int64 {
        curr++
        curr
    }

    public func `match`(tk: TokenKind): Int64 {
        match (peek().kind) {
            case ILLEGAL => 
                diagReportError(peek(), "Expecting ${tk} but got EOF", "Syntax error, unexpected ${peek().kind}") {
                    IllegalArgumentException("Syntax error, unexpected ${peek().kind}")
                }
            case k => if (k == tk) {
                next()
            } else {
                diagReportError(peek(), "Expecting ${tk} but got ${peek().kind}", "Syntax error, unexpected ${peek().kind}") {
                    IllegalArgumentException("Syntax error, unexpected ${peek().kind}")
                }
            }
        }
    }

    public func exprs(): Int64 {
        this.expr()
        this.exprsTail()
    }

    public func exprsTail(): Int64 {
        match (peek().kind) {
            case COMMA => 
                this.`match`(COMMA)
                this.expr()
                this.exprsTail()
            case ILLEGAL => curr
            case tk =>
                diagReportError(peek(), "Expecting ',' or EOF but got ${peek().kind}", "Syntax error, unexpected ${peek().kind}") {
                    IllegalArgumentException("Syntax error, unexpected ${peek().kind}")
                }
        }
    }

    public func expr(): Int64 {
        this.start = this.curr
        this.`match`(IDENTIFIER)
        this.exprTail()
        this.args()
        arr.add(
            if (this.kind == 0) {
                Single(this.input[start..curr])
            } else if (this.kind == 1) {
                Qualified(this.input[start..curr])
            } else if (this.kind == 2) {
                SingleCall(this.input[start..curr])
            } else if (this.kind == 3) {
                QualifiedCall(this.input[start..curr])
            } else {
                throw IllegalStateException("Invalid parser state: Parser.kind = ${this.kind}, please report!")
            }
        )
        this.kind = 0
        this.curr
    }

    public func exprTail(): Int64 {
        match (peek().kind) {
            case DOT =>
                this.kind += 1
                this.`match`(DOT)
                this.`match`(IDENTIFIER)
            case LPAREN | COMMA | ILLEGAL => curr
            case tk =>
                diagReportError(peek(), "Expecting '.' or '(' or EOF but got ${peek().kind}", "Syntax error, unexpected ${peek().kind}") {
                    IllegalArgumentException("Syntax error, unexpected ${peek().kind}")
                }
        }
    }

    public func args(): Int64 {
        match (peek().kind) {
            case LPAREN =>
                this.kind += 2
                this.`match`(LPAREN)
                this.content()
                this.`match`(RPAREN)
            case COMMA | ILLEGAL => curr
            case tk =>
                diagReportError(peek(), "Expecting '(' or ',' or EOF but got ${peek().kind}", "Syntax error, unexpected ${peek().kind}") {
                    IllegalArgumentException("Syntax error, unexpected ${peek().kind}")
                }
        }
    }

    public func content(): Int64 {
        match (peek().kind) {
            case ILLEGAL =>
                diagReportError(peek(), "Expecting more, but got EOF", "Syntax error, unexpected EOF") {
                    IllegalArgumentException("Syntax error, unexpected EOF")
                }
            case LPAREN => 
                this.`match`(LPAREN)
                this.content()
                this.`match`(RPAREN)
                this.content()
            case RPAREN => curr
            case tokenKind =>
                this.`match`(tokenKind)
                this.content()
        }
    }
}
/*
Exprs -> Expr Exprs'
Exprs' -> ',' Expr Exprs' | ε
Expr -> id Expr' Args
Expr' -> '.' id | ε
Args -> '(' Content ')' | ε
Content -> id Content | '(' Content ')' Content | ε
*/
public func deriveImpl(attr: Tokens, input: Tokens): Tokens {
    Parser(attr).parse().iterator()
        .map {
            s => Token(AT) + match (s) {
                case Single(v) => Token(IDENTIFIER, "Derive" + v[0].value).toTokens()
                case Qualified(v) => v[0..2] + Token(IDENTIFIER, "Derive" + v[2].value)
                case SingleCall(v) => Token(IDENTIFIER, "Derive" + v[0].value) + Token(LSQUARE) + v[2..v.size - 1] + Token(RSQUARE)
                case QualifiedCall(v) => v[0..2] + Token(IDENTIFIER, "Derive" + v[2].value) + Token(LSQUARE) + v[4..v.size - 1] + Token(RSQUARE)
            }
        }
        .intersperse(Token(NL).toTokens())
        .fold(quote()) { acc, s => acc + s } + Token(NL) + input
}

func diagReportError<T>(node: T, message: String, hint: String, error: () -> Exception): Nothing where T <: ToTokens {
    diagReport(DiagReportLevel.ERROR, node.toTokens(), message, hint)
    throw error()
}
