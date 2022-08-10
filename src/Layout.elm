module Layout exposing (..)

import Color exposing (rgb)
import Color.Convert exposing (hexToColor)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events exposing (onClick)
import Element.Font as Font
import Element.Input as Input
import Html.Attributes


fromHex : String -> Color
fromHex str =
    case hexToColor str of
        Ok col ->
            let
                x =
                    Color.toRgba col
            in
            Element.rgba x.red x.green x.blue x.alpha

        Err _ ->
            Element.rgb 255 0 0


h3 =
    hx 40


h4 =
    hx 30


hx fontSize element =
    el [ fontWhite, Font.size fontSize ] element


red =
    fromHex "#b63426"


green =
    fromHex "#159587"


black =
    fromHex "#000000"


grey =
    fromHex "#222222"


midGrey =
    fromHex "#666"


orange =
    fromHex "#ffab40"


purple =
    fromHex "#7c4dff"


fontWhite =
    Font.color <| fromHex "#ffffff"


fontBlack =
    Font.color <| fromHex "#000000"


bgGreen =
    Background.color green


bgStriped =
    htmlAttribute <|
        Html.Attributes.style "background" "repeating-linear-gradient(45deg,#222,#222 60px,#333 60px,#333 120px)"


button label msg =
    el [ onClick msg, Border.rounded 100, bgGreen, fontWhite, paddingXY 25 20, Font.size 25 ]
        (text label)


buttonDisabled label =
    el [ Border.rounded 100, Background.color <| fromHex "#E0E0E0", Font.color <| fromHex "#A6A6A6", paddingXY 25 20, Font.size 25 ]
        (text label)


fab label msg =
    el [ Border.rounded 100, Background.color purple, fontWhite, padding 25, Font.size 25, onClick msg, centerX ]
        (text label)
