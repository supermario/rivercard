module Frontend exposing (..)

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Dict exposing (Dict)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events exposing (onClick)
import Element.Font as Font
import Element.Input as Input
import Helpers exposing (..)
import Html
import Lamdera
import Layout exposing (..)
import List.Extra as List
import Page
import Random
import Task
import Time
import Types exposing (..)
import Url


type alias Msg =
    FrontendMsg


type alias Model =
    FrontendModel


app =
    Lamdera.frontend
        { init = init
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = update
        , updateFromBackend = updateFromBackend
        , subscriptions = \m -> Sub.none
        , view =
            \model ->
                { title = "Rivercard"
                , body =
                    [ layout [ width fill, height fill, Background.color grey ] (view model)
                    ]
                }
        }


init : Url.Url -> Nav.Key -> ( Model, Cmd FrontendMsg )
init url key =
    ( { key = key
      , currentPage = Page.pathToPage url
      , formfields = Dict.empty
      , users = initUsers
      , riverTop = 5
      , currentRound = 1
      , currentSuit = 0
      , locked = False
      }
    , generateNewSuit
    )


update : FrontendMsg -> Model -> ( Model, Cmd FrontendMsg )
update msg model =
    if model.locked && msg /= ToggleLock then
        ( model, Cmd.none )

    else
        case msg of
            UrlClicked urlRequest ->
                case urlRequest of
                    Internal url ->
                        ( model
                        , Cmd.batch [ Nav.pushUrl model.key (Url.toString url) ]
                        )

                    External url ->
                        ( model
                        , Nav.load url
                        )

            UrlChanged url ->
                ( model, Cmd.none )

            OpenedPage page ->
                if page == model.currentPage then
                    -- Catch inifite loops!
                    ( model, Cmd.none )

                else
                    ( { model | currentPage = page }, Cmd.batch [ Nav.pushUrl model.key (Page.pageToPath page) ] )

            NewSuit int ->
                ( { model | currentSuit = int }, Cmd.none )

            AddPoint userName ->
                let
                    users =
                        forUser userName model.users incWon

                    incWon user =
                        case user.currentRound of
                            Nothing ->
                                user

                            Just r ->
                                { user | currentRound = Just { r | won = r.won + 1 } }
                in
                ( { model | users = users }, Cmd.none )

            RemovePoint userName ->
                let
                    users =
                        forUser userName model.users decWon

                    decWon user =
                        case user.currentRound of
                            Nothing ->
                                user

                            Just r ->
                                { user | currentRound = Just { r | won = tf (r.won == 0) r.won (r.won - 1) } }
                in
                ( { model | users = users }, Cmd.none )

            SetBid userName bid ->
                let
                    users =
                        forUser userName model.users setBid

                    setBid user =
                        { user | currentRound = Just (Round model.currentRound bid 0) }
                in
                ( { model | users = users }, Cmd.none )

            ResetRound userName ->
                let
                    users =
                        forUser userName model.users reset

                    reset user =
                        { user | currentRound = Nothing }
                in
                ( { model | users = users }, generateNewSuit )

            FinishRound ->
                let
                    finishRound _ user =
                        case user.currentRound of
                            Nothing ->
                                user

                            Just cRound ->
                                { user | rounds = user.rounds ++ [ cRound ], currentRound = Nothing }

                    users =
                        Dict.map finishRound model.users
                in
                ( { model | currentRound = model.currentRound + 1, users = users }, generateNewSuit )

            ResetGame ->
                ( { model
                    | formfields = Dict.empty
                    , users =
                        Dict.map
                            (\k u ->
                                { u
                                    | rounds = []
                                    , currentRound = Nothing
                                }
                            )
                            model.users
                    , riverTop = 2
                    , currentRound = 1
                    , locked = False
                  }
                , generateNewSuit
                )

            ToggleLock ->
                ( { model | locked = not model.locked }, Cmd.none )

            ViewConfig ->
                let
                    usersAsFields =
                        model.users
                            |> Dict.toList
                            |> List.indexedMap
                                (\i ( k, u ) ->
                                    ( "username-" ++ String.fromInt i, k )
                                )
                            |> Dict.fromList
                in
                ( { model | formfields = Dict.union model.formfields usersAsFields }, openedPage Config )

            FormFieldChanged name value ->
                -- ( model, Cmd.none )
                let
                    newForm =
                        model.formfields |> upsert name value
                in
                ( { model | formfields = newForm }, Cmd.none )

            UserAdded ->
                let
                    nextIndex =
                        model.formfields
                            |> Dict.size
                            |> String.fromInt
                in
                ( { model
                    | formfields =
                        Dict.insert ("username-" ++ nextIndex) "" model.formfields
                  }
                , Cmd.none
                )

            ConfigFinished ->
                let
                    fields =
                        model.formfields
                            |> Dict.toList
                            |> List.map Tuple.second

                    usersList =
                        model.users
                            |> Dict.toList
                            |> List.map Tuple.second
                            |> pad (List.length fields) (User "" [] Nothing)

                    newUsers =
                        List.map2
                            (\fieldValue user ->
                                { user | name = fieldValue }
                            )
                            fields
                            usersList
                            |> List.map (\u -> ( u.name, u ))
                            |> Dict.fromList
                in
                ( { model | users = newUsers }, openedPage Game )

            Noop ->
                ( model, Cmd.none )


upsert key value values =
    Dict.update key (always (Just value)) values


pad len default list =
    let
        listLen =
            List.length list
    in
    if listLen < len then
        list ++ List.repeat (len - listLen) default

    else
        list


fieldLabelled : { a | formfields : Dict String String } -> String -> Element FrontendMsg -> Element FrontendMsg
fieldLabelled model key label =
    Input.text [ fontBlack ]
        { onChange = FormFieldChanged key
        , text = getField model.formfields key
        , placeholder = Nothing
        , label = Input.labelAbove [] label
        }


getField : Dict String String -> String -> String
getField fields field =
    fields |> Dict.get field |> Maybe.withDefault ""


updateFromBackend : ToFrontend -> Model -> ( Model, Cmd FrontendMsg )
updateFromBackend msg model =
    ( model, Cmd.none )


subscriptions : a -> Sub msg
subscriptions model =
    Sub.none


forUser : comparable -> Dict.Dict comparable a -> (a -> a) -> Dict.Dict comparable a
forUser userName users func =
    Dict.update userName (Maybe.map func) users


pointsFor : User -> Int
pointsFor user =
    let
        roundPoints r =
            tf (r.bet == r.won) (10 + r.won) 0
    in
    List.sum (List.map roundPoints user.rounds)


view model =
    case model.currentPage of
        Config ->
            column [ centerX ]
                [ model.formfields
                    |> Dict.toList
                    |> List.indexedMap
                        (\i ( k, u ) ->
                            row []
                                [ fieldLabelled model ("username-" ++ String.fromInt i) (text "name:")
                                ]
                        )
                    |> column [ centerX, fontWhite, padding 10, spacing 10 ]
                , button "Add" UserAdded
                , button "Done" ConfigFinished
                ]

        Game ->
            let
                lockedOverlay =
                    el [ height fill, width fill, bgStriped ] none

                locker styles =
                    el ([ width (px 50), height (px 50), onClick ToggleLock, Font.size 50 ] ++ styles)
                        (text <| tf model.locked "🔒" "🔓")

                userWon user =
                    case user.currentRound of
                        Just round ->
                            round.won

                        _ ->
                            0

                roundDone =
                    if getSum userWon model.users == roundsFor model then
                        button "Next Round" FinishRound

                    else
                        text ""

                endState =
                    column [ width fill, spacing 100, padding 20 ]
                        [ el [ centerX ] (h3 <| text "Done!")
                        , userWinView model.users
                        ]

                running =
                    column
                        [ width fill
                        , height fill
                        , behindContent <| tf model.locked lockedOverlay none
                        ]
                        [ row [ width fill, padding 20, height (px 100) ]
                            [ el [ alignLeft ] (button "Reset" ResetGame)
                            , el [ alignLeft ] (button "Config" ViewConfig)
                            , row [ spacing 10, centerX ]
                                [ el [ Border.rounded 100, Background.color orange, fontWhite, padding 25, Font.size 30 ]
                                    (text ("Deal " ++ String.fromInt (roundsFor model) ++ " " ++ pluralise "card" (roundsFor model)))
                                , roundDone
                                ]
                            , locker [ alignRight ]
                            ]
                        , Dict.toList model.users
                            |> List.map (userView model)
                            |> List.greedyGroupsOf 3
                            |> List.map (row [ width fill ])
                            |> column [ width fill, centerY ]
                        , let
                            suitToString si =
                                case si of
                                    1 ->
                                        "♠"

                                    2 ->
                                        "♣"

                                    3 ->
                                        "♥"

                                    4 ->
                                        "♦"

                                    _ ->
                                        ""

                            suitStyle cs s col =
                                if suitToString cs == s then
                                    [ centerX
                                    , Font.color col
                                    , Font.size 50
                                    , Background.color black
                                    , Border.rounded 10
                                    , Border.width 4
                                    , Border.color orange
                                    , padding 10
                                    ]

                                else
                                    [ centerX
                                    , Font.color col
                                    , Font.size 50
                                    , Background.color black
                                    , Border.rounded 10
                                    , padding 14
                                    ]

                            icon cs s col =
                                el
                                    (suitStyle cs s col)
                                    (text s)
                          in
                          row [ width fill, padding 20, alignBottom, spacing 5 ]
                            [ locker [ alignLeft ]
                            , icon model.currentSuit "♠" midGrey
                            , icon model.currentSuit "♣" midGrey
                            , icon model.currentSuit "♥" red
                            , icon model.currentSuit "♦" red
                            , locker [ alignRight ]
                            ]
                        ]

                done =
                    model.riverTop * 2
            in
            tf (model.currentRound == done) endState running


roundsFor : { a | currentRound : Int, riverTop : Int } -> Int
roundsFor model =
    if model.currentRound <= model.riverTop then
        model.currentRound

    else
        model.riverTop - modBy model.riverTop model.currentRound


theeZeroBets : User -> Bool
theeZeroBets user =
    let
        lastThreeRounds =
            user.rounds |> List.reverse |> List.take 3

        lastThreeBets =
            List.map .bet lastThreeRounds
    in
    List.length lastThreeBets == 3 && List.sum lastThreeBets == 0


leadingUser : Dict.Dict comparable User -> String
leadingUser users =
    let
        byPoints =
            List.sortBy pointsFor (Dict.values users)

        topUser =
            List.head (List.reverse byPoints)

        noUser =
            ""
    in
    case topUser of
        Nothing ->
            noUser

        Just u ->
            case pointsFor u of
                0 ->
                    noUser

                _ ->
                    u.name


userView : Model -> ( String, User ) -> Element Msg
userView model ( name, user ) =
    let
        pointsFab =
            el
                [ Font.size 25
                , Background.color <| fromHex "#2196f3"
                , Border.rounded 100
                , paddingXY 10 5
                , fontWhite
                ]
                (text <| String.fromInt <| pointsFor user)

        nameLine =
            row
                [ Font.bold, fontWhite, Font.size 34, spacing 10, centerX ]
                [ crown
                , el [ onClick <| ResetRound user.name ] (text user.name)
                , pointsFab
                ]

        crown =
            case leadingUser model.users == user.name of
                True ->
                    el [ Font.size 50 ] (text "👑")

                False ->
                    text ""
    in
    column [ spacing 20, padding 20, width fill ] <|
        case user.currentRound of
            -- No bet made yet
            Nothing ->
                [ nameLine
                , List.range 0 (roundsFor model)
                    |> List.map (betButton user)
                    |> row [ spacing 30, centerX ]
                ]

            -- Bet made
            Just cRound ->
                let
                    t =
                        String.fromInt cRound.won ++ " / " ++ String.fromInt cRound.bet
                in
                [ nameLine
                , row [ spacing 30, width fill, centerX ]
                    [ fab t (AddPoint name)
                    , if cRound.won > 0 then
                        el [ centerX ] (button "-" (RemovePoint name))

                      else
                        text ""
                    ]
                ]


userWinView : Dict.Dict comparable User -> Element msg
userWinView users =
    let
        userMarkup user =
            column [ spacing 10, width fill ]
                [ el [ fontWhite, Font.size 40, centerX ] (text user.name)
                , el [ fontWhite, Font.size 30, centerX ] (text <| "Points: " ++ (String.fromInt <| pointsFor user))
                ]

        sortedUsers =
            List.sortBy pointsFor (Dict.values users)
    in
    List.map userMarkup sortedUsers
        |> List.reverse
        |> List.greedyGroupsOf 3
        |> List.map (row [ width fill ])
        |> column [ width fill, spacing 40 ]


betButton : User -> Int -> Element Msg
betButton user index =
    case theeZeroBets user && index == 0 of
        True ->
            buttonDisabled (String.fromInt index)

        False ->
            button (String.fromInt index) (SetBid user.name index)


generateNewSuit =
    Random.generate NewSuit (Random.int 1 4)


openedPage page =
    trigger (OpenedPage page)


trigger : msg -> Cmd msg
trigger msg =
    Task.perform (always msg) Time.now
