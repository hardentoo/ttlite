package superspec.tt.test

import superspec.tt._

class ReplSpec extends org.scalatest.FunSpec {

  describe("TT REPL should process without errors") {
    it("core") {
      TTREPL.main(Array("examples/core.hs"))
    }
    it("dproduct") {
      TTREPL.main(Array("examples/dproduct.hs"))
    }
    it("nat") {
      TTREPL.main(Array("examples/nat.hs"))
    }
    it("product") {
      TTREPL.main(Array("examples/product.hs"))
    }
    it("sum") {
      TTREPL.main(Array("examples/sum.hs"))
    }
    it("list") {
      TTREPL.main(Array("examples/list.hs"))
    }
    it("eq") {
      TTREPL.main(Array("examples/eq.hs"))
    }
    it("vec") {
      TTREPL.main(Array("examples/vec.hs"))
    }
    it("fin") {
      TTREPL.main(Array("examples/fin.hs"))
    }
    it("misc") {
      TTREPL.main(Array("examples/misc.hs"))
    }
  }
}

