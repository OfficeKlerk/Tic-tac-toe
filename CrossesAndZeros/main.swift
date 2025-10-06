import Foundation

//состояния игры
enum GameState {
    case play
    case draw
    case crossWin
    case zeroWin
}

//создание игрового поля
func createNewMap(_ size: Int) -> [[Character]] {
    return Array(repeating: Array(repeating: "-", count: size), count: size)
}

//вывод игрового поля
func printMap(_ map: [[Character]], _ size: Int) {
    print("====" + String(repeating: "=", count: size*2 - 1) + "====")
    for row in map {
        print("|   ", terminator: "")
        for col in row{
            print("\(col) ", terminator: "")
        }
        print("  |")
    }
    print("====" + String(repeating: "=", count: size*2 - 1) + "====")
}

//применить ход
func applyMove(_ map: inout [[Character]], team: Character, row: Int, col: Int, _ size: Int) -> Bool {
    if (row < 0 || row >= size || col < 0 || col >= size) {
            return false   //нельзя выйти за границы
    }
    if (team != "X" && team != "O") {
        return false // нельзя поставить ничего кроме X или O
    }
    
    //если дошли сюда, значит индексы и команда корректные
    if (map[row][col] != "-") {
        return false   // нельзя затирать чужой ход
    }
    
    //ход допустим
    map[row][col] = team
    return true
}

//проверка состояния игры
func checkState(_ map: [[Character]], _ winPatterns: [[[Int]]]) -> GameState {
    
    //проверка на чью-либо победу
    for pattern in winPatterns {
        //проверка победы крестиков
        let crossWin = pattern.allSatisfy { coordinate in
            let row = coordinate[0]
            let col = coordinate[1]
            return map[row][col] == "X"
        }
        if crossWin {
            return .crossWin
        }
        
        //проверка победы ноликов
        let zeroWin = pattern.allSatisfy { coordinate in
            let row = coordinate[0]
            let col = coordinate[1]
            return map[row][col] == "O"
        }
        if zeroWin {
            return .zeroWin
        }
    }
    
    //проверка на ничью
    for row in map {
        if row.contains("-") {
            return .play
        }
    }
    return .draw
}

//игрок против игрока
func playPvPGame(_ size: Int) {
    var map = createNewMap(size)
    var team: Character = "X"
    var isEnd = false
    
    while !isEnd {
        printMap(map, size)
        print("Ходят \(team). Введите ваш ход")
        print("строка (1–\(size)): ", terminator: "")
        
        //проверяем корректность ввода
        if let rowStr = readLine(), let row = Int(rowStr) {
            print("столбец (1–\(size)): ", terminator: "")
            if let colStr = readLine(), let col = Int(colStr) {
                if !applyMove(&map, team: team, row: row - 1, col: col - 1, size) {
                    print("Некорректный ввод. Попробуйте снова")
                    continue
                }
            }
            else {
                print("Некорректный ввод. Попробуйте снова")
                continue
            }
        }
        else {
            print("Некорректный ввод. Попробуйте снова")
            continue
        }
        
        let state = checkState(map, generateWinPatterns(size))
        switch state {
        case .play:
            team = (team == "X") ? "O" : "X"
        case .draw:
            print("Игра окончена. Ничья.")
            isEnd = true
        case .crossWin:
            print("Игрока окончена. Победили крестики.")
            isEnd = true
        case .zeroWin:
            print("Игра окончена. Победили нолики.")
            isEnd = true
        }
    }
    printMap(map, size)
}

//игрок против компьютера
func playPvEGame(_ size: Int) {
    var map = createNewMap(size)
    var team: Character = "X"
    var isEnd = false
    
    while !isEnd {
        printMap(map, size)
        
        //инициализируем переменные(потом значения поменяются во время ввода)
        var row: Int = -1
        var col: Int = -1
        
        if team == "X" {
            //игрок
            print("Ходит игрок. Введите ход")
            print("строка (1–\(size)): ", terminator: "")
            if let rowStr = readLine(), let row = Int(rowStr) {
                print("столбец (1–\(size)): ", terminator: "")
                if let colStr = readLine(), let col = Int(colStr) {
                    if !applyMove(&map, team: team, row: row - 1, col: col - 1, size) {
                        print("Некорректный ввод. Попробуйте снова")
                        continue
                    }
                }
                else {
                    print("Некорректный ввод. Попробуйте снова")
                    continue
                }
            }
            else {
                print("Некорректный ввод. Попробуйте снова")
                continue
            }
        }
        else {
            //компьютер
            let bestMove = findTheBestMove(&map, size)
            row = bestMove[0]
            col = bestMove[1]
            //если по какой-то причине ф-я вернула некорректное значение(такого быть не должно)
            if !applyMove(&map, team: team, row: row, col: col, size) {
                print("Непредвиденная ошибка...")
                isEnd = true
            }
            print("Компьютер сделал ход. Строка - \(row), столбец - \(col)")
        }
        
        let state = checkState(map, generateWinPatterns(size))
        switch state {
        case .play:
            team = (team == "X") ? "O" : "X"
        case .draw:
            print("Игра окончена. Ничья.")
            isEnd = true
        case .crossWin:
            print("Игра окончена. Крестики выиграли.")
            isEnd = true
        case .zeroWin:
            print("Игра окончена. Нолики выиграли.")
            isEnd = true
        }
    }
    printMap(map, size)
}

//функция для нахождения наил6учшего хода компьютера
//по сути - тот же chooseOptimalMove, только здесь мы возвращаем кординаты хода
func findTheBestMove(_ map: inout [[Character]], _ size: Int) -> [Int] {
    var bestScore = -10000000;
    var bestMove = [-1, -1]
    
    //вводим ограничение по глубине рекурсии. Если поле 3х3, то можно без ограничения
    //но при поле 6х6 программа зависнет (будет 36! вызовов)
    let maxDepth: Int
        switch size {
        case 3:
            maxDepth = 9
        case 4:
            maxDepth = 5
        case 5:
            maxDepth = 4
        case 6:
            maxDepth = 3
        default:
            maxDepth = 3
        }
    
    for i in 0..<size{
        for j in 0..<size{
            if map[i][j] == "-"{
                map[i][j] = "O"
                let score = chooseOptimalMove(&map, "X", size, depth: 1, maxDepth)
                map[i][j] = "-"
                if score > bestScore{
                    bestScore = score;
                    bestMove = [i, j]
                }
            }
        }
    }
    return bestMove;
}

//вспомогательная функция для вычисления наилучшего хода компьютера
func chooseOptimalMove(_ map: inout [[Character]], _ team: Character, _ size: Int, depth: Int, _ maxDepth: Int) -> Int {
    //проверяем состояние игры
    let state = checkState(map, generateWinPatterns(size))
    switch(state) {
    case .zeroWin:
        return 10000000 - depth; //приоритет хода будет в зависимости от глубины
    case .crossWin:
        return -10000000 + depth;
    case .draw:
        return 0;
    case .play:
        //функция продолжается
        break
    }
    
    //проверяем, достигли ли мы ограничения по глубине рекурсии
    if depth >= maxDepth{
        return evaluateCurrentPosition(map, size)
    }
    
    //если играет компьютер
    //проходим по каждой пустой клетке, ставим туда "О" и рекурсивно проверяем следующие ходы
    //таким образом строится дерево всевозможных ходов. Программа возвращает многие выигрышные ходы,
    //мы выберем первый попавшийся
    if team == "O"{
        var bestScore = -10000000;
        for i in 0..<size{
            for j in 0..<size{
                if map[i][j] == "-"{
                    map[i][j] = "O";
                    let score = chooseOptimalMove(&map, "X", size, depth: depth + 1, maxDepth);
                    map[i][j] = "-"
                    if score > bestScore {
                        bestScore = score;
                    }
                }
            }
        }
        return bestScore;
    }
    else {
        //если ход игрока (виртуальный)
        //тут тот же алгоритм, но для игрока. Так мы рассматриваем "идеального" игрока, хотя
        //он может играть и неправильно
        var bestScore = 10000000;
        for i in 0..<size{
            for j in 0..<size{
                if map[i][j] == "-"{
                    map[i][j] = "X";
                    let score = chooseOptimalMove(&map, "O", size, depth: depth + 1, maxDepth);
                    map[i][j] = "-"
                    if score < bestScore {
                        bestScore = score;
                    }
                }
            }
        }
        return bestScore;
    }
}

//ф-я генерации массива победных комбинаций
//пример
//[[0, 0], [0, 1], [0, 2]] (строка), [[0, 0], [1, 0], [2, 0]] (столбец), [[0, 0], [1, 1], [2, 2]] (диагональ)
func generateWinPatterns(_ size: Int) -> [[[Int]]]{
    var winPatterns: [[[Int]]] = []
    
    //строки
    for i in 0..<size {
        var rowPattern: [[Int]] = []
        for j in 0..<size {
            rowPattern.append([i, j])
        }
        winPatterns.append(rowPattern)
    }
    
    //столбцы
    for j in 0..<size {
        var colPattern: [[Int]] = []
        for i in 0..<size {
            colPattern.append([i, j])
        }
        winPatterns.append(colPattern)
    }
    
    //главная диагональ
    var mainDiagonal: [[Int]] = []
    for i in 0..<size {
        mainDiagonal.append([i, i])
    }
    winPatterns.append(mainDiagonal)
    
    //побочная диагональ
    var antiDiagonal: [[Int]] = []
    for i in 0..<size {
        antiDiagonal.append([i, size - 1 - i])
    }
    winPatterns.append(antiDiagonal)
    
    return winPatterns
}

//ф-я оценивает текущее состояние поля
//она работает по следующему принципу: "чем больше ноликов тем лучше"
//кроме того, "очки", которые начисляются в этом методе, весят меньше, чем очки,
//которые начисляются непосредственно в методе chooseOptimalMove
//таким образом, компьютер выберет приоритетом ход с выигрышом, чем обычный ход
func evaluateCurrentPosition(_ map: [[Character]], _ size: Int) -> Int{
    var score = 0
    
    for row in map {
        for cell in row {
            if cell == "O" {
                score += 1
            }
            if cell == "X" {
                score -= 1
            }
        }
    }
    return score
}

//ф-я запуска игры
func startTheGame() {
    let error = "Некорректный ввод"
    
    print("Введите размер поля (от 3 до 6): ", terminator: "")
    if let input = readLine(), let size = Int(input) {
        if size < 3 || size > 6 {
            print(error)
            return
        }
        print("Выберите режим игры:")
        print("1 - Игрок против игрока")
        print("2 - Игрок против компьютера")
        print("Введите номер режима: ", terminator: "")
        
        if let input = readLine(), let mode = Int(input) {
            if mode == 1 {
                playPvPGame(size)
            }
            else if mode == 2 {
                playPvEGame(size)
            }
            else {
                print(error)
            }
        }
        else {
            print(error)
        }
    }
    else {
        print(error)
    }
}

startTheGame()
