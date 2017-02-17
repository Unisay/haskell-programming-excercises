module Vigenere where

import Data.Char
import Data.List()

enumerate :: String -> [Int]
enumerate = cycle . map ord

shiftBounded :: Int -> Int -> Int -> Char -> Char
shiftBounded lower upper n c
  | pos < lower = chr $ dis + pos + 1
  | pos > upper = chr $ pos - dis - 1
  | otherwise = chr pos
  where
    pos = mod n dis + ord c
    dis = upper - lower

shiftR :: Char -> Int -> Char
shiftR c n
  | isUpper c = shiftBounded (ord 'A') (ord 'Z') n c
  | otherwise = shiftBounded (ord 'a') (ord 'z') n c

shiftL :: Char -> Int -> Char
shiftL c i = shiftR c (1 - i)

encode :: String -> String -> String
encode password s = zipWith shiftR s (enumerate password)

decode :: String -> String -> String
decode password s = zipWith shiftL s (enumerate password)
