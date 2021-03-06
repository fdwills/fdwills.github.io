# Swift语言

```
println("Hello, world")
```

---

## 常量与变量

* 用let定义常量， 用var定义变量
* 可以不指定类型，编译器自动判断
* 也可以显示指定类型

```
// 变量
var myVariable = 42
myVariable = 50

// 常量
let myConstant = 42
let explicitDouble: Double = 7
```
--

```
let label = "The width is "
let width = 94
let widthLabel = label + String(width)
```

---

## 类型

```
// Integer
var integerVariable = 42
// Double
var doubleVariable = 42.00
// Float
var floatVariable: Float = 42.00
```
---

## 字符串

```
// String
var stringVariable = "hello"
// \()可以将表达式内置与字符串内
var stringVariable2 = "the value is \(floatVariable + integerVariable) \n"
```

---

## 数组

```
var shoppingList = ["catfish", "water", "tulips", "blue paint"]
shoppingList[1] = "bottle of water"

// 空的数组
var emptyArray = String[]()
emptyArray = []
```

---

## 字典

```
var occupations = [
    "Malcolm": "Captain",
    "Kaylee": "Mechanic",
]
occupations["Jayne"] = "Public Relations"

// 空字典
var emptyDictionary = Dictionary<String, Float>()
emptyDictionary = [:]
```

---

## 控制流

* 条件分支
  - if
  - switch
* 循环分支
  - for-in
  - for
  - while
  - do-while

--

```
let individualScores = [75, 43, 103, 87, 12]
var teamScore = 0
for score in individualScores {
    if score > 50 {
        teamScore += 3
    } else {
        teamScore += 1
    }
}
teamScore
```

--

```
let vegetable = "red pepper"
switch vegetable {
case "celery":
    let vegetableComment = "Add some raisins and make ants on a log."
case "cucumber", "watercress":
    let vegetableComment = "That would make a good tea sandwich."
case let x where x.hasSuffix("pepper"):
    let vegetableComment = "Is it a picy \(x)?"
default:
    let vegetableComment = "Everything tastes good in soup."
}
```

--

```
var firstForLoop = 0
for i in 0..3 {
    firstForLoop += i
}
firstForLoop
 
var secondForLoop = 0
for var i = 0; i < 3; ++i {
    secondForLoop += 1
}
secondForLoop
```

--

```
let interestingNumbers = [
    "Prime": [2, 3, 5, 7, 11, 13],
    "Fibonacci": [1, 1, 2, 3, 5, 8],
    "Square": [1, 4, 9, 16, 25],
]
var largest = 0
for (kind, numbers) in interestingNumbers {
    for number in numbers {
        if number > largest {
            largest = number
        }
    }
}
largest
```

--

```
var n = 2
while n < 100 {
    n = n * 2
}
n

var m = 2
do {
    m = m * 2
} while m < 100
m
```

---

## 函数定义与调用
c++
```
string greet(string name, string day) {
    return name + ", today is " + day;
}
```

swift

```
func greet(name: String, day: String) -> String {
    return "\(name), today is \(day)."
}

// 返回多个值
func getGasPrices() -> (Double, Double, Double) {
    return (3.59, 3.69, 3.79)
}
// 传入多个值（当数组处理）
func sumOf(numbers: Int...) -> Int {
    var sum = 0
    for number in numbers {
        sum += number
    }
    return sum
}
sumOf()
sumOf(1, 2, 3)
```

--

函数可以嵌套

```
func returnFifteen() -> Int {
    var y = 10
    func add() {
        y += 5
    }
    add()
    return y
}
returnFifteen()
```
--

函数的参数可以是函数

```
func hasAnyMatches(list: Int[], condition: Int -> Bool) -> Bool {
    for item in list {
        if condition(item) {
            return true
        }
    }
    return false
}
func lessThanTen(number: Int) -> Bool {
    return number < 10
}
var numbers = [20, 19, 7, 12]
hasAnyMatches(numbers, lessThanTen)
```
--

函数的返回值可以是函数

```
func makeIncrementer() -> (Int -> Int) {
    func addOne(number: Int) -> Int {
        return 1 + number
    }
    return addOne
}
var increment = makeIncrementer()
increment(7)
```

--

其他用法：代码块
```
numbers.map({
    (number: Int) -> Int in
    let result = 3 * number
    return result
    })

sort([1, 5, 3, 12, 2]) { $0 > $1 }

```

---

## 类

* 关键字是class
* 类成员变量的定义方法与普通变量常量定义方法一致
* 类的成员函数的定义函数与普通函数一样
* 通过.来调用引用变量和函数
* 构造函数init
* 析构函数deinit
* 基类函数重写override

--

```
class Shape: BaseShape {
    var numberOfSides = 0
    var name: String
    var sideLength: Double = 0.

    var perimeter: Double {
      get {
        return 3.0 * sideLength
      }
      set {
        sideLength = newValue / 3.0 // newValue是传入的隐式变量名, 可以显示的在set后指定变量名
      }
    }

    init(name: String) {
        self.name = name
        super.init()
    }

    deinit {
        println('deinit!')
    }

    func simpleDescription() -> String {
        return "A shape with \(numberOfSides) sides."
    }

    override description func () -> String {
        return "A square with sides of length \(sideLength)."
    }
}

var shape = Shape()
var shape = Shape(name: 'Round')
shape.numberOfSides = 7
shape.perimeter
shape.perimeter = 10.0
var shapeDescription = shape.simpleDescription()
```
--

set和get

willset和didset

```
class TriangleAndSquare {
    var triangle: EquilateralTriangle {
    willSet {
        square.sideLength = newValue.sideLength
    }
    }
    var square: Square {
    willSet {
        triangle.sideLength = newValue.sideLength
    }
}
```

--

方法的对外名和对内名


函数

```
func sum(num : Int) -> Int {
    return num + num + num
}
sum(10)
```

类方法

```
class test {
    func sum(firstNum : Int, secondNum : Int, thirdNum num3 : Int) -> Int {
      return firstNum + secondNum + num3
    }
}
var obj = test()
obj.sum(fistNum: 5, secondNum: 6, thirdNum:7)
obj.sum(5,6,7)
obj.sum(5, secondNum:6, thirdNum:7)
```
---

## 枚举类型

```
enum Rank: Int {
    case Ace = 1
    case Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten
    case Jack, Queen, King
    func simpleDescription() -> String {
        switch self {
        case .Ace:
            return "ace"
        case .Jack:
            return "jack"
        case .Queen:
            return "queen"
        case .King:
            return "king"
        default:
            return String(self.toRaw())
        }
    }
}
let ace = Rank.Ace
let aceRawValue = ace.toRaw()
```
---


