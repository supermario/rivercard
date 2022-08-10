module Helpers exposing (getAll, getSum, pluralise, tf)

import Dict


tf : Bool -> a -> a -> a
tf c t f =
    if c then
        t

    else
        f


pluralise : String -> Int -> String
pluralise word count =
    tf (count == 1) word (word ++ "s")


getAll : (v -> b) -> Dict.Dict comparable v -> List b
getAll func users =
    List.map func (Dict.values users)


getSum : (v -> number) -> Dict.Dict comparable v -> number
getSum func dict =
    List.sum (getAll func dict)
