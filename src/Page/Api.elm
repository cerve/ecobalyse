module Page.Api exposing (..)

import Data.Session exposing (Session)
import Html exposing (..)
import Html.Attributes exposing (..)
import Views.Container as Container


type alias Model =
    ()


type Msg
    = NoOp


init : Session -> ( Model, Session, Cmd Msg )
init session =
    ( (), session, Cmd.none )


update : Session -> Msg -> Model -> ( Model, Session, Cmd Msg )
update session msg model =
    case msg of
        NoOp ->
            ( model, session, Cmd.none )


view : Session -> Model -> ( String, List (Html Msg) )
view session _ =
    ( "Exemples"
    , [ Container.centered [ class "pb-5" ]
            [ h1 [ class "mb-3" ] [ text "API Wikicarbone" ]
            , p [] [ text "L'API HTTP Wikicarbone permet de calculer les impacts environnementaux des produits textiles." ]
            , node "rapi-doc"
                -- RapiDoc options: https://mrin9.github.io/RapiDoc/api.html
                [ attribute "spec-url" (session.clientUrl ++ "data/openapi.yaml")
                , attribute "theme" "light"
                , attribute "font-size" "largest"
                , attribute "load-fonts" "false"
                , attribute "layout" "column"
                , attribute "show-info" "false"
                , attribute "update-route" "false"
                , attribute "render-style" "view"
                , attribute "show-header" "false"
                , attribute "show-components" "true"
                , attribute "schema-description-expanded" "true"
                , attribute "allow-authentication" "false"
                , attribute "allow-server-selection" "false"
                , attribute "allow-api-list-style-selection" "false"
                ]
                []
            ]
      ]
    )