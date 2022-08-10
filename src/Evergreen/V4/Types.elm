module Evergreen.V4.Types exposing (..)

import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Dict exposing (Dict)
import Lamdera exposing (SessionId)
import Url exposing (Url)


type alias FrontendModel =
    { key : Key
    , currentPage : Page
    , formfields : Dict String String
    , users : Dict String User
    , riverTop : Int
    , currentRound : Int
    , currentSuit : Int
    , locked : Bool
    }


type alias User =
    { name : String
    , rounds : List Round
    , currentRound : Maybe Round
    }


initUsers =
    Dict.fromList
        [ ( "Jane", User "Jane" [] Nothing )
        , ( "Mark", User "Mark" [] Nothing )
        ]


type alias Round =
    { number : Int
    , bet : Int
    , won : Int
    }


type alias Username =
    String


type alias BackendModel =
    { configStores : Dict SessionId Config
    }


type alias Config =
    Dict String User


type FrontendMsg
    = UrlClicked UrlRequest
    | UrlChanged Url
    | OpenedPage Page
    | NewSuit Int
    | AddPoint Username
    | RemovePoint Username
    | SetBid Username Int
    | ResetRound Username
    | FinishRound
    | ResetGame
    | ToggleLock
    | ViewConfig
    | FormFieldChanged String String
    | UserAdded
    | ConfigFinished
    | Noop


type Page
    = Game
    | Config


type ToBackend
    = NoOpToBackend


type BackendMsg
    = NoOpBackendMsg


type ToFrontend
    = NoOpToFrontend
