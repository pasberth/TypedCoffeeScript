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
