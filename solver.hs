import Data.List

-- usun znaki interpunkcyjne (nie powinny wystapic)
removePunc :: String -> String
removePunc xs = [ x | x <- xs, not (x `elem` ",.?!-:;\"\'") && x /= ' ']

-- aplikacja removePunc dla zbioru slow
ignoreIrrelevantSigns :: [String] -> [String]
ignoreIrrelevantSigns [] = []
ignoreIrrelevantSigns (x:xs) = removePunc x : ignoreIrrelevantSigns xs

addNumberToLetterHelper :: Int -> String -> [(Char, Int)]
addNumberToLetterHelper _ [] = []
addNumberToLetterHelper num (x:xs) = (x, num) : addNumberToLetterHelper (num + 1) xs

addNumberToCrosswordHelper :: Int -> [String] -> [[(Char, Int)]]
addNumberToCrosswordHelper _ [] = []
addNumberToCrosswordHelper row ((x):xs) = addNumberToLetterHelper (length x * row) x : addNumberToCrosswordHelper (row + 1) xs

-- ponumeruj litery z planszy
addNumberToCrossword :: [String] -> [[(Char, Int)]]
addNumberToCrossword = addNumberToCrosswordHelper 0

-- wczytaj plik z opisem planszy z literami
readCrossword :: FilePath -> IO [[(Char, Int)]]
readCrossword path = do
  crossword <- readFile path
  let processedCrossword = addNumberToCrossword (lines crossword)
  return processedCrossword

-- wczytaj plik z listą słów do wykreślenia
readWords :: FilePath -> IO [String]
readWords path = do
  words <- readFile path
  let processedWords = ignoreIrrelevantSigns (lines words)
  return processedWords

-- transponuj plansze z literami
transposeCrossword :: [[(Char, Int)]] -> [[(Char, Int)]]
transposeCrossword ([]:_) = []
transposeCrossword x = map head x : transposeCrossword (map tail x)

-- usun pierwszy wiersz planszy
removeFirstRow :: [[(Char, Int)]] -> [[(Char, Int)]]
removeFirstRow [[]] = []
removeFirstRow ((x):xs) = xs

diagonal :: [[(Char, Int)]] -> [(Char, Int)]
diagonal [] = []
diagonal ([]:_) = []
diagonal ((x):xs) = head x : diagonal (map tail xs)

-- 
antidiagonal :: [[(Char, Int)]] 
              -> [(Char, Int)]
antidiagonal [] = []
antidiagonal ([]:_) = []
antidiagonal ((x):xs) = last x : antidiagonal (map init xs)

-- diagonale rozpoczynające się od kolejnych kolumn
allDiagonals :: [[(Char, Int)]] -> [[(Char, Int)]]
allDiagonals [] = []
allDiagonals x = [diagonal x] ++ [reverse (antidiagonal x)] ++ allDiagonals (removeFirstRow x)

getAllCombinations :: [[(Char, Int)]] -> [[(Char, Int)]]
getAllCombinations [[]] = []
getAllCombinations crossword = crossword ++ transposeCrossword crossword ++ allDiagonals crossword ++ allDiagonals (transposeCrossword crossword)

printElements :: [(Char, Int)] -> Int -> Int -> IO()
printElements [] _ _  = putStrLn ""
printElements ((a,b):c) 0 crwrdLength = do
    putStrLn([a])
    printElements c crwrdLength crwrdLength

printElements ((a,b):c) num crwrdLength = do
  putStr([a])
  printElements c (num - 1) crwrdLength

printList :: String ->  IO()
printList [] = do putStrLn ""
printList (x:xs) = do putStr [x]
                      printList xs

printSolution :: [String] -> IO()
printSolution [] = do putStr ""
printSolution (x:xs) = do printList x
                          printSolution xs


findString' :: String          -- ^ string to search for
            -> String          -- ^ string to search in
            -> Maybe Int       -- ^ starting index
findString' _ [] = Nothing
findString' [] _ = Nothing
findString' search str = findIndex (isPrefixOf search) (tails str)

-- 
findString :: String           -- ^ string to search for
            -> [(Char, Int)]   -- ^ row to search in
            -> Maybe [Int]     -- ^ list of indexes
findString _ [] = Nothing
findString [] _ = Nothing
findString search str = do 
  idx <- findString' search (map fst str)
  return (map snd . take (length search) . drop idx $ str)

-- Find word in crossword
findWord :: String              -- ^ word
          -> [[(Char, Int)]]    -- ^ all combinations of crossword
          -> Maybe [Int]        -- ^ list of indexes
findWord _ [] = Nothing
findWord [] _ = Nothing
findWord word [x] = findString word x
findWord word (x:xs) = if (findString word x) == Nothing 
                        then findWord word xs
                      else findString word x

removeLetter' :: [(Char, Int)] -> Int -> [(Char, Int)]
removeLetter' [] _ = []
removeLetter' [(a,b)] idx = []
removeLetter' ((a,b):c) idx | b == idx = c
                            | otherwise = [(a,b)] ++ (removeLetter' c idx)

-- Remove letter with given index form crossword 
removeLetter :: [[(Char, Int)]]  -- ^ crossword
              -> Int             -- ^ index of letter to remove
              -> Int             -- ^ number of cols in crossword
              -> [[(Char, Int)]] -- ^ updated crossword
removeLetter [] _ _ = []   
removeLetter [x] idx cols = [removeLetter' x idx]          
removeLetter (x:xs) idx cols | idx < 0 = (x:xs)
                             | idx < cols = ((removeLetter' x idx): xs)
                             | otherwise = (x:(removeLetter xs idx (cols+cols)))

-- -- Remove letters with given list of numbers form crossword 
-- removeWord :: [[(Char, Int)]]    -- ^ crossword
--               -> Maybe [Int]     -- ^ indexes of letter to remove
--               -> Int             -- ^ number of cols in crossword
--               -> [[(Char, Int)]] -- ^ updated crossword
-- removeWord cross (Just []) cols = cross
-- removeWord cross xs cols = case xs of
--   Just n -> removeWord (removeLetter cross (head n) cols) (Just (tail n)) cols
--   Nothing -> cross

-- Remove letters with given list of numbers form crossword 
removeWord :: [[(Char, Int)]]    -- ^ crossword
              -> [Int]           -- ^ indexes of letter to remove
              -> Int             -- ^ number of cols in crossword
              -> [[(Char, Int)]] -- ^ updated crossword
removeWord cross [] cols = cross
removeWord cross [x] cols = removeLetter cross x cols
removeWord cross (x:xs) cols = removeWord (removeLetter cross x cols) xs cols

-- Solve the crossword
solve :: [[(Char, Int)]]  -- ^ crossword
      -> [String]         -- ^ list of words to find
      -> [[(Char, Int)]]  -- ^ solution
solve cross [] = cross
solve cross [w] = 
  case findWord w (getAllCombinations cross) of
    Just n -> removeWord cross n 11
    Nothing -> error w
solve cross (w:ws) = solve (solve cross [w]) ws

-- solve cross words =
--   case findWord "JULIET" (getAllCombinations cross) of
--     Just n -> removeWord cross n 11
--     Nothing -> error "world not found"

main :: IO ()
main = do
  cross <- readCrossword "data1/crossword"
  words <- readWords "data1/words" 
  -- print words
  -- print (getAllCombinations cross)
  -- print (solve cross ["BRIDE", "CARDS","CARESS", "CHOCOLATE"])
  -- print (removeWord (removeWord cross "ARROW" 11) "ADORER" 11)
  print (solve cross ["ADORER", "ARROW"])

-- ["ADORER","ARROW","BOUQUET","BRIDE","CARDS","CARESS","CHOCOLATE","COUPLE","CUPID","DATE","DATING","DEVOTION","EMBRACE","FIRST","KISS","GROOM","HEART","HUGS","ISEULT","LOVE","LUCK","LYRE","ODE","POEM","PRESENT","QUEEN","RENDEZVOUS","RING","ROMEO","ROSES","RYE","SCENTS","SENSE","SONG","SWEET","TRISTAN","WEDDING"]