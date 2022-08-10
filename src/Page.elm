module Page exposing (..)

import Dict
import Lamdera exposing (Url)
import Types exposing (..)


pageToPath : Page -> String
pageToPath page =
    case page of
        Game ->
            "/"

        Config ->
            "/config"


pathToPage : Url -> Page
pathToPage url =
    [ ( "/", Game )
    , ( "/config", Config )
    ]
        |> Dict.fromList
        |> Dict.get url.path
        |> Maybe.withDefault Game
