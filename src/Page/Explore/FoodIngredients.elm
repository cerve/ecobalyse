module Page.Explore.FoodIngredients exposing (table)

import Data.Dataset as Dataset
import Data.Food.Builder.Db as BuilderDb
import Data.Food.Ingredient as Ingredient exposing (Ingredient)
import Data.Food.Origin as Origin
import Data.Food.Process as Process
import Data.Gitbook as Gitbook
import Data.Scope exposing (Scope)
import Data.Unit as Unit
import Html exposing (..)
import Html.Attributes exposing (..)
import Page.Explore.Table exposing (Table)
import Route
import Views.Icon as Icon
import Views.Link as Link


table : BuilderDb.Db -> { detailed : Bool, scope : Scope } -> Table Ingredient msg
table _ { detailed, scope } =
    [ { label = "Identifiant"
      , toCell =
            \ingredient ->
                if detailed then
                    code [] [ text (Ingredient.idToString ingredient.id) ]

                else
                    a [ Route.href (Route.Explore scope (Dataset.FoodIngredients (Just ingredient.id))) ]
                        [ code [] [ text (Ingredient.idToString ingredient.id) ] ]
      }
    , { label = "Nom"
      , toCell = .name >> text
      }
    , { label = "Origine par défaut"
      , toCell = .defaultOrigin >> Origin.toLabel >> text
      }
    , { label = "Rapport cru/cuit"
      , toCell =
            \{ rawToCookedRatio } ->
                div [ classList [ ( "text-end", not detailed ) ] ]
                    [ rawToCookedRatio
                        |> Unit.ratioToFloat
                        |> String.fromFloat
                        |> text
                    , Link.smallPillExternal
                        [ href (Gitbook.publicUrlFromPath Gitbook.FoodRawToCookedRatio) ]
                        [ Icon.question ]
                    ]
      }
    , { label = "Procédé conventionnel"
      , toCell = .default >> .name >> Process.nameToString >> text
      }
    , { label = "Procédé biologique"
      , toCell =
            .variants
                >> .organic
                >> Maybe.map (.name >> Process.nameToString)
                >> Maybe.withDefault "N/A"
                >> text
      }
    ]
