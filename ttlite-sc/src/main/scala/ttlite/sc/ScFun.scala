package ttlite.sc

import ttlite.common._
import ttlite.core._

trait FunDriver extends Driver with FunEval {

  override def nv(t: Neutral): Option[Name] = t match {
    case NApp(NFree(n), _) => Some(n)
    case NApp(n, _) => nv(n)
    case _ => super.nv(t)
  }

  override def elimVar(n: Name, nt: Value): DriveStep = nt match {
    case VPi(_, _) => StopDStep
    case _ => super.elimVar(n, nt)
  }

  // TODO: it is possible to decompose application if the inner "operator" is neutral
  // TODO: like \x -> elimList x ...
  // TODO: or like (elimList x ....) x
  // TODO: but I think, in general it should be configurable
  override def decompose(c: Conf): DriveStep = c.term match {
    case _ =>
      super.decompose(c)
  }
}

trait FunResiduator extends Residuator with FunDriver
trait FunProofResiduator extends ProofResiduator with FunResiduator {
  self: FunAST with IdAST =>
}
