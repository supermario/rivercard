module Evergreen.V1.Types exposing (..)

import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Dict
import Url exposing (Url)


type alias FrontendModel =
    { key : Key
    , users : Dict.Dict String User
    , riverTop : Int
    , currentRound : Int
    , locked : Bool
    }


type alias User =
    { name : String
    , rounds : List Round
    , currentRound : Maybe Round
    }


type alias Round =
    { number : Int
    , bet : Int
    , won : Int
    }


type alias Username =
    String


type alias BackendModel =
    { message : String
    }


type FrontendMsg
    = UrlClicked UrlRequest
    | UrlChanged Url
    | AddPoint Username
    | RemovePoint Username
    | SetBid Username Int
    | ResetRound Username
    | FinishRound
    | ResetGame
    | ToggleLock
    | Noop


type ToBackend
    = NoOpToBackend


type BackendMsg
    = NoOpBackendMsg


type ToFrontend
    = NoOpToFrontend
