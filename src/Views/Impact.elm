module Views.Impact exposing
    ( impactQuality
    , impactSelector
    , selector
    , viewDefinition
    )

import Data.Gitbook as Gitbook
import Data.Impact as Impact
import Data.Scope exposing (Scope)
import Data.Unit as Unit
import Html exposing (..)
import Html.Attributes as Attr exposing (..)
import Html.Events exposing (..)
import Views.Button as Button
import Views.Icon as Icon
import Views.Link as Link
import Views.Markdown as Markdown


qualityDocumentationUrl : String
qualityDocumentationUrl =
    Gitbook.publicUrlFromPath Gitbook.ImpactQuality


viewDefinition : Impact.Definition -> Html msg
viewDefinition { source, label, description, quality } =
    div [ class "ImpactDefinition d-none d-sm-block card shadow-sm text-dark bg-light px-2 py-1 mb-3" ]
        [ div [ class "row" ]
            [ div [ class "col-9" ]
                [ h2 [ class "fs-6 lh-base text-muted fw-bold my-1" ]
                    [ span [ class "me-1" ] [ Icon.info ]
                    , text "Impact étudié\u{00A0}: "
                    , text label
                    ]
                ]
            , div [ class "col-3 text-end" ]
                (impactQuality quality
                    ++ [ viewSource source ]
                )
            ]
        , div [ class "text-muted fs-7" ]
            [ Markdown.simple [ class "mb-1" ] description ]
        ]


impactQuality : Impact.Quality -> List (Html msg)
impactQuality quality =
    let
        maybeInfo =
            case quality of
                Impact.NotFinished ->
                    Just
                        { cls = "btn-danger"
                        , icon = Icon.build
                        , label = "N/A"
                        , help = "Impact en cours de construction"
                        }

                Impact.GoodQuality ->
                    Just
                        { cls = "btn-success"
                        , icon = Icon.checkCircle
                        , label = "I"
                        , help = "Qualité satisfaisante"
                        }

                Impact.AverageQuality ->
                    Just
                        { cls = "btn-info"
                        , icon = Icon.info
                        , label = "II"
                        , help = "Qualité satisfaisante mais nécessitant des améliorations"
                        }

                Impact.BadQuality ->
                    Just
                        { cls = "btn-warning"
                        , icon = Icon.warning
                        , label = "III"
                        , help = "Donnée incomplète à utiliser avec prudence"
                        }

                Impact.UnknownQuality ->
                    Nothing
    in
    case maybeInfo of
        Just { cls, icon, label, help } ->
            [ a
                [ class <| Button.pillClasses ++ " fs-7 py-0 " ++ cls
                , target "_blank"
                , href qualityDocumentationUrl
                , title help
                ]
                [ icon
                , text "Qualité\u{00A0}: "
                , strong [] [ text label ]
                ]
            ]

        Nothing ->
            []


viewSource : Impact.Source -> Html msg
viewSource source =
    Link.smallPillExternal
        [ href source.url
        , title <| "Source des données pour cet impact : " ++ source.label
        ]
        [ Icon.question ]


type alias SelectorConfig msg =
    { impacts : List Impact.Definition
    , selectedImpact : Impact.Trigram
    , switchImpact : Impact.Trigram -> msg
    , selectedFunctionalUnit : Unit.Functional
    , switchFunctionalUnit : Unit.Functional -> msg
    , scope : Scope
    }


impactSelector : SelectorConfig msg -> Html msg
impactSelector { impacts, selectedImpact, switchImpact, scope } =
    let
        toOption ({ trigram, label } as impact) =
            option
                [ Attr.selected (selectedImpact == impact.trigram)
                , value <| Impact.toString trigram
                ]
                [ text label ]

        scopeImpacts =
            impacts
                |> List.filter (.scopes >> List.member scope)
    in
    select
        [ class "form-select"
        , onInput (Impact.trg >> switchImpact)
        ]
        [ scopeImpacts
            |> List.filter Impact.isAggregate
            |> List.map toOption
            |> optgroup [ attribute "label" "Impacts agrégés" ]
        , scopeImpacts
            |> List.filter (Impact.isAggregate >> not)
            |> List.sortBy .label
            |> List.map toOption
            |> optgroup [ attribute "label" "Impacts détaillés" ]
        ]


funitSelector : SelectorConfig msg -> List (Html msg)
funitSelector { selectedFunctionalUnit, switchFunctionalUnit } =
    [ ( Unit.PerItem, Icon.tShirt )
    , ( Unit.PerDayOfWear, Icon.day )
    ]
        |> List.map
            (\( funit, icon ) ->
                button
                    [ type_ "button"
                    , title <| Unit.functionalToString funit
                    , class "btn d-flex align-items-center gap-1"
                    , classList
                        [ ( "btn-primary", funit == selectedFunctionalUnit )
                        , ( "btn-outline-primary", funit /= selectedFunctionalUnit )
                        ]
                    , onClick (switchFunctionalUnit funit)
                    ]
                    [ icon ]
            )


selector : SelectorConfig msg -> Html msg
selector config =
    impactSelector config
        :: funitSelector config
        |> div [ class "ImpactSelector input-group" ]
