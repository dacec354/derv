protected package derv.test

import std.unittest.* // cjlint-ignore !G.PKG.01
import std.unittest.testmacro.* // cjlint-ignore !G.PKG.01
import std.unittest.testmacro
import std.ast.* // cjlint-ignore !G.PKG.01
import derv.impl.deriveImpl

@Test
class DeriveImplTests {

    func expectTokens(source: Tokens, expected: Tokens): Unit {
        @Expect(compareTokens(source, expected))
    }

    // @Skip   
    @TestCase
    func testSingle(): Unit {
        let attr = quote(Hashable, Builder, ToString)
        let input = quote(class Hello {})
        let output = deriveImpl(attr, input)
        this.expectTokens(output, quote(\@DeriveHashable(\@DeriveBuilder(\@DeriveToString($input)))))
    }

    // @Skip
    @TestCase
    func testQualified(): Unit {
        let attr = quote(derv.Hashable, derive.Builder, deriving.ToString, hash.HashEqual)
        let input = quote(class Hello {})
        let output = deriveImpl(attr, input)
        println(output)
        this.expectTokens(output, quote(\@derv.DeriveHashable(\@derive.DeriveBuilder(\@deriving.DeriveToString(\@hash.DeriveHashEqual($input))))))
    }

    // @Skip
    @TestCase
    func testSingleCall(): Unit {
        let attr = quote(Hashable(1), Builder(2), ToString(3))
        let input = quote(class Hello {})
        let output = deriveImpl(attr, input)
        println(output)
        this.expectTokens(output, quote(\@DeriveHashable[1](\@DeriveBuilder[2](\@DeriveToString[3]($input)))))
    }

    // @Skip
    @TestCase
    func testQualifiedCall(): Unit {
        let attr = quote(derv.Hashable("1"), derive.Builder("4"), deriving.ToString("5"), hash.HashEqual("7"))
        let input = quote(class Hello {})
        let output = deriveImpl(attr, input)
        println(output)
        this.expectTokens(output, quote(\@derv.DeriveHashable["1"](\@derive.DeriveBuilder["4"](\@deriving.DeriveToString["5"](\@hash.DeriveHashEqual["7"]($input))))))
    }

    // @Skip
    @TestCase
    func testComplicatedSingleCall(): Unit {
        let attr = quote(Builder(init = false), ToString(1(5)6(())), Hashable([{..fds))
        let input = quote(class Hello {})
        let output = deriveImpl(attr, input)
        this.expectTokens(output, quote(\@DeriveBuilder[init = false](\@DeriveToString[1(5)6(())](\@DeriveHashable[[{..fds]($input)))))
    }

    // @Skip
    @TestCase
    func testComplicatedQualifiedCall(): Unit {
        let attr = quote(derive_builder.Builder(init = false), derive.Builder(1(5)6(())), derive.ToString(5), hash.HashEqual(5))
        let input = quote(class Hello {})
        let output = deriveImpl(attr, input)
        println(output)
        this.expectTokens(output, quote(\@derive_builder.DeriveBuilder[init = false](\@derive.DeriveBuilder[1(5) 6(())](\@derive.DeriveToString[5](\@hash.DeriveHashEqual[5]($input))))))
    }
}