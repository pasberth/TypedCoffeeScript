suite 'TypeChecker', ->
  suite 'Assignment', ->
    test 'basic assign', ->
      x :: Number = 3
      eq x, 3

    test 'basic assign', ->
      x :: Number = 3
      x = 5
      eq x, 5

    test 'assign function', ->
      f :: Number -> Number = (n) -> n
      g :: Number -> Number = f

    test 'throw type mismatch', ->
      throws ->
        CoffeeScript.parse """
          x :: Number = "3"
        """

    test 'object assign', ->
      obj :: { x :: Number} = { x : 2}

    test 'throw object literal mitmatching', ->
      throws ->
        CoffeeScript.parse """
          obj :: { x :: Number } = { x : '' }
        """

    test 'throw at lacking of object member', ->
      throws ->
        CoffeeScript.parse """
          obj :: { x :: Number, y :: Number } = { x : 3 }
        """

    test 'throw member access error', ->
      throws ->
        CoffeeScript.parse """
          obj :: { x :: Number } = { x : 3 }
          obj.x = ""
        """

    test 'object literal with newline', ->
      p :: {
        x :: Number
        y :: Number
      } = {x : 1, y: 5}

    test 'any type thorough everything', ->
      a :: Any = 3
      a = false
      eq a, false

    test 'typed function', ->
      f :: Number -> Number = (n :: Number) :: Number ->  n * n

    test 'typed function that has 2 arguments', ->
      f :: Number * Number -> Number = (n :: Number, m :: Number) :: Number ->  n * m

    test 'typed function that has 3 arguments', ->
      f :: Number * Number * Number -> Number = (n :: Number, m :: Number, r :: Number) :: Number ->  n * m * r

    test 'typed function type mismatch', ->
      throws ->
        CoffeeScript.compile """
          f :: Number -> Number = (n :: Number) :: String ->  n * n
        """

    test 'typed function and binding', ->
      f :: Number -> Number = (n :: Number) ->  n * n
      n :: Number  = f 4

    test 'typed function mismatching application', ->
      throws ->
        CoffeeScript.parse """
          f :: Number -> Number = 3
        """

    test 'typed function with return type', ->
      f :: Number -> Number = (n :: Number) :: Number ->  n * n
      n :: Number  = f 4

    test 'return function type', ->
      fh = (n :: Number) :: (Number -> Number) -> (m)-> n * m
      eq fh(2)(3), 6

    test 'avoid polution about prototype', ->
      class X
      X::x = 3
      eq X.prototype.x, 3

    test 'struct definition', ->
      struct Point {
        x :: Number
        y :: Number
      }
      p :: Point = {x: 3, y: 3}

    test 'struct definition with symbol', ->
      struct A {
        num :: Number
      }

      struct Point {
        x :: Number
        y :: {
          a :: A
          b :: String
        }
      }
      p :: Point = {x: 3, y: {a : {num: 4} , b : 'foo'}}

    test 'nested struct definition', ->
      struct Point {
        x :: Number
        y :: {
          a :: Number
          b :: String
        }
      }
      p :: Point = {x: 3, y: {a : 1 , b : 'foo'}}

    test 'throw struct member access with mismatch type', ->
      throws ->
        CoffeeScript.parse """
          struct Point {
            x :: Number
            y :: Number
          }
          p :: Point = {x:3, y:3}
          p.x = "hoge"
        """

    test 'void', ->
      nf :: () -> () = -> setTimeout (->), 100
      nf()

    test 'void keyword', ->
      nf :: () -> void = -> setTimeout (->), 100
      nf()

    test 'throw function arguments mismatch', ->
      throws ->
        CoffeeScript.parse """
          f :: Number -> Number = (n :: Number) :: Number ->  n * n
          (f "hello")
        """

    test 'void keyword', ->
      f :: Number -> Number = (n :: Number) :: Number ->  n * n
      x :: Number = (f 3)

    test 'throw function arguments mismatch', ->
      throws ->
        CoffeeScript.parse """
          f :: Number -> Number = (n :: Number) :: Number ->  n * n
          y :: String = (f 3)
        """

    test 'typed array', ->
      struct Point {
        x :: Number
        y :: Number
      }
      p :: Point = {x: 3, y: 2}
      tarr :: Point[]  = [{x : 3, y: 3}, {x : 3, y: 3}, p]


    test 'if', ->
      f :: Number -> Number = (n) -> n

      tf :: () -> Boolean = -> true
      a :: Number =
        if tf()
          if true
            f 4
          else
            6
        else if true
          4
        else
          8

    test 'throw if return type mismatch', ->
      throws ->
        CoffeeScript.parse """
          a :: Number = if true then 3 else ""
        """

    test 'for in' , ->
      list :: Number[] =
        for i :: Number, n in [1..3]
          nn :: Number  = 3
          nn

      list2 :: Number[] =
        for i :: Number, n in [1..3]
          i

      list3 :: Number[] =
        for i :: Number, n in [1..3]
          n

    test 'throw return type mismatch', ->
      throws ->
        CoffeeScript.parse """
          arr :: Number[] = ("" for i in [1,2,3])
        """

    test 'throw target mismatch', ->
      throws ->
        CoffeeScript.parse """
          arr :: Number[] = (i for i :: Number in [1,2,""])
        """

    test 'for of', ->
      list :: Number[] =
        for key :: String, val :: Number of {x: 77, y: 6}
          val

    test 'throw target mismatch', ->
      throws -> CoffeeScript.parse """
      list :: Number[] =
        for key :: String, val :: Number of {x: "hoge", y: 6}
          val
      """

    test 'function return type', ->
      f0 :: () -> Number = () :: Number -> 3

    test 'function return type mismatch with block', ->
      list :: Number[] =
      f1 :: () -> Number = () :: Number ->
        3

    test 'throw function return type mismatch', ->
      throws -> CoffeeScript.parse """
      f0 :: () -> Number = () :: Number -> ''
      """

    test 'throw function return type mismatch', ->
      throws -> CoffeeScript.parse """
      f2 :: () -> Number = ->
        return ""
      """

    test 'Range', ->
      list :: Number[] = [1..10]

    test 'throw function return type mismatch', ->
      throws -> CoffeeScript.parse """
      list :: String[] = [1..10]
      """

    test 'BinOps Num', ->
      a :: Number = (3 + 3 * 6) / 2

    test 'BinOps String', ->
      a :: String = "hello" + "world"

    test 'miscast BinOp', ->
      throws -> CoffeeScript.parse """
      c :: Number = "" + 3
      """

    test 'Switch', ->
      x :: String =
        switch true
          when 0
            'foo'
          when 1
            'bar'
          else
            'fuga'
    test 'miscast Switch', ->
      throws -> CoffeeScript.parse """
      x :: Number =
        switch true
          when 0
            1
          else
            'str'
      """

    test 'cant catch undefined', ->
      throws -> CoffeeScript.parse """
      x :: Number = global?.require
      """

    test 'basic assign', ->
      x :: Number = 3
      eq x, 3

    test 'new', ->
      class X
        f: (n :: Number) :: Number -> 
          n * n
      x :: X = new X
      n :: Number = x.f 3

    test 'new', ->
      throws -> CoffeeScript.parse """
      class X
        f: (n :: Number) :: Number -> 
          n * n
      x :: X = new X
      n :: String = x.f 3
      """

    test 'new', ->
      struct Singleton<T> {
        getInstance :: () -> T
      }

      struct Point {
        x :: Number
        y :: Number
      }

      origin :: Singleton<Point> = {
        getInstance: -> {x: 0, y: 0}
      }
