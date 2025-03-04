macro package derv

import std.ast.* // cjlint-ignore !G.PKG.01
import derv.impl.deriveImpl

public macro Derive(input: Tokens, attr: Tokens): Tokens {
    deriveImpl(input, attr)
}