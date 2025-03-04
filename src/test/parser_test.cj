protected package derv.test

import std.unittest.* // cjlint-ignore !G.PKG.01
import std.unittest.testmacro.* // cjlint-ignore !G.PKG.01
import std.ast.* // cjlint-ignore !G.PKG.01
import derv.impl.{Parser, SubTerm}

@Test
class ParserTests {

    func expectSingle(source: SubTerm, target: Tokens): Unit {
        match (source) {
            case Single(v) => @Expect(compareTokens(v, target))
            case Qualified(v) => @FailExpect("expected single token, but got qualified ${v}")
            case SingleCall(v) => @FailExpect("expected single token, but got single call ${v}")
            case QualifiedCall(v) => @FailExpect("expected single token, but got qualified call ${v}")
        }
    }

    func expectQualified(source: SubTerm, target: Tokens): Unit {
        match (source) {
            case Single(v) => @FailExpect("expected qualified token, but got single ${v}")
            case Qualified(v) => @Expect(compareTokens(v, target))
            case SingleCall(v) => @FailExpect("expected qualified token, but got single call ${v}")
            case QualifiedCall(v) => @FailExpect("expected qualified token, but got qualified call ${v}")
        }
    }

    func expectSingleCall(source: SubTerm, target: Tokens): Unit {
        match (source) {
            case Single(v) => @FailExpect("expected single call, but got single ${v}")
            case Qualified(v) => @FailExpect("expected single call, but got qualified ${v}")
            case SingleCall(v) => @Expect(compareTokens(v, target))
            case QualifiedCall(v) => @FailExpect("expected single call, but got qualified call ${v}")
        }
    }

    func expectQualifiedCall(source: SubTerm, target: Tokens): Unit {
        match (source) {
            case Single(v) => @FailExpect("expected qualified call, but got single ${v}")
            case Qualified(v) => @FailExpect("expected qualified call, but got qualified ${v}")
            case SingleCall(v) => @FailExpect("expected qualified call, but got single call ${v}")
            case QualifiedCall(v) => @Expect(compareTokens(v, target))
        }
    }

    @TestCase
    func testSingle(): Unit {
        let input = quote(Hashable, Builder, ToString)
        let arr = Parser(input).parse()
        this.expectSingle(arr[0], quote(Hashable))
        this.expectSingle(arr[1], quote(Builder))
        this.expectSingle(arr[2], quote(ToString))
    }

    @TestCase
    func testQualified(): Unit {
        let input = quote(derv.Hashable, derive.Builder, deriving.ToString, hash.HashEqual)
        let arr = Parser(input).parse()
        println(arr)
        this.expectQualified(arr[0], quote(derv.Hashable))
        this.expectQualified(arr[1], quote(derive.Builder))
        this.expectQualified(arr[2], quote(deriving.ToString))
        this.expectQualified(arr[3], quote(hash.HashEqual))
    }

    // @Skip
    @TestCase
    func testSingleCall(): Unit {
        let input = quote(Hashable(), Builder(), ToString())
        let arr = Parser(input).parse()
        this.expectSingleCall(arr[0], quote(Hashable()))
        this.expectSingleCall(arr[1], quote(Builder()))
        this.expectSingleCall(arr[2], quote(ToString()))
    }

    // @Skip
    @TestCase
    func testQualifiedCall(): Unit {
        let input = quote(derv.Hashable(), derive.Builder(), deriving.ToString(), hash.HashEqual())
        let arr = Parser(input).parse()
        this.expectQualifiedCall(arr[0], quote(derv.Hashable()))
        this.expectQualifiedCall(arr[1], quote(derive.Builder()))
        this.expectQualifiedCall(arr[2], quote(deriving.ToString()))
        this.expectQualifiedCall(arr[3], quote(hash.HashEqual()))
    }

    // @Skip
    @TestCase
    func testComplicatedSingleCall(): Unit {
        let input = quote(Builder(init = false), ToString(1(5)6(())), Hashable([{..fds))
        let arr = Parser(input).parse()
        // println(arr)
        this.expectSingleCall(arr[0], quote(Builder(init = false)))
        this.expectSingleCall(arr[1], quote(ToString(1(5)6(()))))
        this.expectSingleCall(arr[2], quote(Hashable([{..fds)))
    }

    // @Skip
    @TestCase
    func testComplicatedQualifiedCall(): Unit {
        let input = quote(derive_builder.Builder(init = false), derive.Builder(1(5)6(())), derive.ToString(), hash.HashEqual(5))
        let arr = Parser(input).parse()
        // println(arr)
        this.expectQualifiedCall(arr[0], quote(derive_builder.Builder(init = false)))
        this.expectQualifiedCall(arr[1], quote(derive.Builder(1(5)6(()))))
        this.expectQualifiedCall(arr[2], quote(derive.ToString()))
        this.expectQualifiedCall(arr[3], quote(hash.HashEqual(5)))
    }
}