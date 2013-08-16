package superspec.tt

import org.kiama.output.PrettyPrinter

// TODO: make an object or package object
trait Common extends PrettyPrinter {
  // meta-syntax
  sealed trait Name
  case class Global(n: String) extends Name
  case class Assumed(n: String) extends Name
  case class Local(i: Int) extends Name
  case class Quote(i: Int) extends Name

  sealed trait MetaTerm
  case class MApp(t1: MetaTerm, t2: MetaTerm) extends MetaTerm
  case class MAnn(t1: MetaTerm, t2: MetaTerm) extends MetaTerm
  // typed binders
  case class Binder(tp: MetaTerm, body: MetaTerm) extends MetaTerm

  type Result[A] = Either[String, A]
  type NameEnv[V] = Map[Name, V]

  // commands
  trait Stmt[+I, +TInf]
  case class Let[I](n: String, i: I) extends Stmt[I, Nothing]
  case class Assume[TInf](ns: List[(String, TInf)]) extends Stmt[Nothing, TInf]
  case class Eval[I](e: I) extends Stmt[I, Nothing]
  case class Import(s: String) extends Stmt[Nothing, Nothing]

  val ids = "abcdefghijklmnopqrstuvwxyz"
  val suffs = List("", "1")
  val vars = for {j <- suffs; i <- ids} yield s"$i$j"

  def parensIf(b: Boolean, d: Doc) =
    if (b) parens(d) else d

  case class TypeError(msg: String) extends Exception(msg)

  import scala.language.postfixOps
  import scala.util.parsing.combinator.{PackratParsers, ImplicitConversions}
  import scala.util.parsing.combinator.syntactical.StandardTokenParsers
  import scala.util.parsing.combinator.lexical.StdLexical

  class MetaLexical extends StdLexical {
    import scala.util.parsing.input.CharArrayReader._
    override def whitespace: Parser[Any] = rep(
      whitespaceChar
        | '/' ~ '*' ~ comment
        | '/' ~ '/' ~ rep( chrExcept(EofCh, '\n') )
        | '-' ~ '-' ~ rep( chrExcept(EofCh, '\n') )
        | '/' ~ '*' ~ failure("unclosed comment")
    )
    override def identChar = letter | elem('_') | elem('$')
  }

  object MetaParser extends StandardTokenParsers with PackratParsers with ImplicitConversions {
    type C = List[String]
    type Res[A] = C => A

    lazy val term: PackratParser[Res[MetaTerm]] = null
  }
}


trait REPL extends Common {
  import scala.language.postfixOps
  import scala.util.parsing.combinator.PackratParsers
  import scala.util.parsing.combinator.syntactical.StandardTokenParsers
  import scala.util.parsing.combinator.lexical.StdLexical
  import org.kiama.util.JLineConsole

  trait Command
  case class TypeOf(in: String) extends Command
  case class Compile(cf: CompileForm) extends Command
  case class Reload(f: String) extends Command
  case object Browse extends Command
  case object Quit extends Command
  case object Help extends Command
  case object Noop extends Command

  trait CompileForm
  case class CompileInteractive(s: String) extends CompileForm
  case class CompileFile(f: String) extends CompileForm

  case class Cmd(cs: List[String], argDesc: String, f: String => Command, info: String)

  type T // term
  type V // value

  val int: Interpreter
  def initialState: State
  private var batch: Boolean = false

  case class State(interactive: Boolean, ne: NameEnv[V], ctx: NameEnv[V], modules: Set[String])

  def handleError() {
    if (batch) {
      throw new Exception
    }
  }

  def output(x: Any) {
    if (!batch) {
      Console.println(x)
    }
  }

  class CoreLexical extends StdLexical {
    import scala.util.parsing.input.CharArrayReader._
    override def whitespace: Parser[Any] = rep(
      whitespaceChar
        | '/' ~ '*' ~ comment
        | '/' ~ '/' ~ rep( chrExcept(EofCh, '\n') )
        | '-' ~ '-' ~ rep( chrExcept(EofCh, '\n') )
        | '/' ~ '*' ~ failure("unclosed comment")
    )
    override def identChar = letter | elem('_') | elem('$')
  }

  trait Interpreter extends StandardTokenParsers with PackratParsers {
    override val lexical = new CoreLexical

    val prompt: String
    def itype(ne: NameEnv[V], ctx: NameEnv[V], i: T): Result[V]
    def iquote(v: V): T
    def ieval(ne: NameEnv[V], i: T): V
    def icprint(c: T): String
    def itprint(t: V): String
    val iParse: Parser[T]
    val stmtParse: Parser[Stmt[T, T]]
    def assume(s: State, x: (String, T)): State

    def parseIO[A](p: Parser[A], in: String): Option[A] = phrase(p)(new lexical.Scanner(in)) match {
      case t if t.successful =>
        Some(t.get)
      case t              =>
        Console.println(s"cannot parse: $t")
        None
    }

    def iinfer(ne: NameEnv[V], ctx: NameEnv[V], i: T): Option[V] = {
      itype(ne, ctx, i) match {
        case Right(t) =>
          Some(t)
        case Left(msg) =>
          Console.println(msg)
          None
      }
    }
  }
  // TODO
  def helpTxt(cs: List[Cmd]): String = ""
  def commands: List[Cmd] =
    List(
      Cmd(List(":type"),      "<expr>", x => TypeOf(x),               "print type of expression"),
      Cmd(List(":browse"),    "",       x => Browse,                  "browse names in scope"),
      Cmd(List(":load"),      "<file>", x => Compile(CompileFile(x)), "load program from file"),
      Cmd(List(":reload"),    "<file>", x => Reload(x),               "reload program from file"),
      Cmd(List(":quit"),      "",       x => Quit,                    "exit interpreter"),
      Cmd(List(":help",":?"), "",       x => Help,                    "display this list of commands")
    )

  def interpretCommand(s: String): Command = {
    val in = s.trim.replaceAll(" +", " ")
    if (in.startsWith(":")) {
      val (cmd, t) = in.span(!_.isWhitespace)
      commands.filter(_.cs.exists(_.startsWith(cmd))) match {
        case Nil =>
          Console.println(s"Unknown command `$cmd'. Type :? for help.")
          Noop
        case c :: Nil =>
          c.f(t.trim)
        case matching =>
          Console.println(s"Ambiguous command, could be ${matching.map(_.cs.head).mkString(", ")}.")
          Noop
      }
    } else {
      Compile(CompileInteractive(in))
    }
  }

  def handleCommand(state: State, cmd: Command): State =
    cmd match {
      case Quit =>
        sys.exit()
      case Noop =>
        state
      case Help =>
        Console.println(helpTxt(commands))
        state
      case Browse =>
        state.ne.keys.foreach{case Global(n) => Console.println(n)}
        state
      case TypeOf(x) =>
        int.parseIO(int.iParse, x) match {
          case Some(e) => int.iinfer(state.ne, state.ctx, e) match {
            case Some(t) =>
              output(s"${int.itprint(t)};")
            case None =>
              handleError()
          }
          case None =>
            handleError()
        }
        state
      case Compile(CompileInteractive(s)) =>
        int.parseIO(int.stmtParse, s) match {
          case Some(stm) => handleStmt(state, stm)
          case None => state
        }
      case Compile(CompileFile(f)) =>
        load(f, state, reload = false)
      case Reload(f) =>
        load(f, state, reload = true)
    }

  def handleStmt(state: State, stmt: Stmt[T, T]): State = {
    def checkEval(s: String, it: T): State = {
      int.iinfer(state.ne, state.ctx, it) match {
        case None =>
          handleError()
          state
        case Some(tp) =>
          val v = int.ieval(state.ne, it)
          if (s == "it"){
            output(int.icprint(int.iquote(v)) + "\n::\n" + int.itprint(tp) + ";")
          } else {
            output(s"$s \n::\n ${int.itprint(tp)};")
          }
          State(state.interactive, state.ne + (Global(s) -> v),  state.ctx + (Global(s) -> tp), state.modules)
      }
    }
    stmt match {
      case Assume(ass) => ass.foldLeft(state)(int.assume)
      case Let(x, e) => checkEval(x, e)
      case Eval(e) => checkEval("it", e)
      case Import(f) => load(f, state, reload = false)
    }
  }

  private def load(f: String, state: State, reload: Boolean): State = {
    if (state.modules(f) && ! reload) return state
    try {
      val input = scala.io.Source.fromFile(f).mkString("")
      val parsed = int.parseIO(int.stmtParse+, input)
      parsed match {
        case Some(stmts) =>
          val s1 = stmts.foldLeft(state){(s, stm) => handleStmt(s, stm)}
          s1.copy(modules = s1.modules + f)
        case None =>
          handleError()
          state
      }
    } catch {
      case io: java.io.IOException =>
        handleError()
        Console.println(s"Error: ${io.getMessage}")
        state
    }
  }

  var state: State = _

  def loop() {
    val in = JLineConsole.readLine(int.prompt)
    val cmd = interpretCommand(in)
    state = handleCommand(state, cmd)
    loop()
  }

  def init() {
    state = initialState
  }

  def main(args: Array[String]) {
    init()
    args match {
      case Array() =>
        loop()
      case Array("-i", f) =>
        Compile(CompileFile(f))
        state = handleCommand(state, Compile(CompileFile(f)))
      case _ =>
        batch = true
        val cmds = args.map(f => Compile(CompileFile(f)))
        for (cmd <- cmds) {
          state = handleCommand(state, cmd)
        }
    }
  }
}