module Views.Textile.BarChart exposing (Bar, view)

import Array
import Data.Impact as Impact
import Data.Textile.Product as Product
import Data.Textile.Simulator exposing (Simulator)
import Data.Textile.Step.Label as Label
import Data.Unit as Unit
import Html exposing (..)
import Html.Attributes exposing (..)
import List.Extra as LE
import Views.Format as Format
import Views.PieChart as PieChart


type alias Config =
    { simulator : Simulator
    , impact : Impact.Definition
    , funit : Unit.Functional
    }


type alias Bar msg =
    { label : Html msg
    , score : Float
    , width : Float
    , percent : Float
    }


makeBars : Config -> List (Bar msg)
makeBars { simulator, impact, funit } =
    let
        grabImpact =
            Impact.grabImpactFloat funit simulator.daysOfWear impact.trigram

        maxScore =
            simulator.lifeCycle
                |> Array.map grabImpact
                |> Array.push (grabImpact simulator.transport)
                |> Array.toList
                |> List.maximum
                |> Maybe.withDefault 0

        stepBars =
            simulator.lifeCycle
                |> Array.toList
                |> List.filter (\{ label } -> label /= Label.Distribution)
                |> List.map
                    (\step ->
                        { label =
                            span []
                                [ case ( step.label, simulator.inputs.product.fabric ) of
                                    ( Label.Fabric, Product.Knitted _ ) ->
                                        text "Tricotage"

                                    ( Label.Fabric, Product.Weaved _ _ ) ->
                                        text "Tissage"

                                    _ ->
                                        text (Label.toString step.label)
                                ]
                        , score = grabImpact step
                        , width = clamp 0 100 (grabImpact step / maxScore * toFloat 100)
                        , percent = grabImpact step / grabImpact simulator * toFloat 100
                        }
                    )

        transportBar =
            { label = text "Transport total"
            , score = grabImpact simulator.transport
            , width = clamp 0 100 (grabImpact simulator.transport / maxScore * toFloat 100)
            , percent = grabImpact simulator.transport / grabImpact simulator * toFloat 100
            }
    in
    stepBars
        -- Move transport bar at ante-penultimate position
        |> LE.splitAt 4
        |> (\( a, b ) -> a ++ transportBar :: b)


barView : Config -> Bar msg -> Html msg
barView { impact } bar =
    tr [ class "fs-7" ]
        [ th [ class "text-end text-truncate py-1 pe-1" ] [ bar.label ]
        , td [ class "d-none d-sm-block text-end py-1 ps-1 pe-2 text-truncate" ]
            [ Format.formatImpactFloat impact bar.score
            ]
        , td [ class "w-100 py-1" ]
            [ div
                [ class "bg-primary"
                , style "height" "1rem"
                , style "line-height" "1rem"
                , style "width" (String.fromFloat bar.width ++ "%")
                ]
                []
            ]
        , td [ class "d-none d-sm-block text-end py-1 ps-2 text-truncate" ]
            [ Format.percent bar.percent ]
        , td [ class "ps-2" ] [ PieChart.view bar.percent ]
        ]


view : Config -> Html msg
view config =
    table [ class "mb-0" ]
        [ makeBars config
            |> List.map (barView config)
            |> tbody []
        ]
