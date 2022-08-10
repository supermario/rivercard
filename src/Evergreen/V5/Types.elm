module Evergreen.V5.Types exposing (..)

import Browser
import Browser.Navigation
import Dict
import Lamdera
import Url


type Page
    = Game
    | Config


type alias Round =
    { number : Int
    , bet : Int
    , won : Int
    }


type alias User =
    { name : String
    , rounds : List Round
    , currentRound : Maybe Round
    }


type alias FrontendModel =
    { key : Browser.Navigation.Key
    , currentPage : Page
    , formfields : Dict.Dict String String
    , users : Dict.Dict String User
    , riverTop : Int
    , currentRound : Int
    , currentSuit : Int
    , locked : Bool
    }


type alias Config =
    Dict.Dict String User


type alias BackendModel =
    { configStores : Dict.Dict Lamdera.SessionId Config
    }


type alias Username =
    String


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
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


type ToBackend
    = NoOpToBackend


type BackendMsg
    = NoOpBackendMsg


type ToFrontend
    = NoOpToFrontend
