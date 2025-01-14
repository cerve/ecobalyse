module Data.Textile.Step.Label exposing
    ( Label(..)
    , all
    , decodeFromCode
    , encode
    , fromCodeString
    , toGitbookPath
    , toString
    )

import Data.Gitbook as Gitbook
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as DE
import Json.Encode as Encode


type Label
    = Material -- Matière
    | Spinning -- Filature
    | Fabric -- Tissage ou Tricotage
    | Ennobling -- Ennoblissement
    | Making -- Confection
    | Distribution -- Distribution
    | Use -- Utilisation
    | EndOfLife -- Fin de vie


all : List Label
all =
    [ Material
    , Spinning
    , Fabric
    , Ennobling
    , Making
    , Distribution
    , Use
    , EndOfLife
    ]


toString : Label -> String
toString label =
    case label of
        Material ->
            "Matière"

        Spinning ->
            "Filature"

        Fabric ->
            "Tissage & Tricotage"

        Making ->
            "Confection"

        Ennobling ->
            "Ennoblissement"

        Distribution ->
            "Distribution"

        Use ->
            "Utilisation"

        EndOfLife ->
            "Fin de vie"


fromCodeString : String -> Result String Label
fromCodeString code =
    case code of
        "material" ->
            Ok Material

        "spinning" ->
            Ok Spinning

        "fabric" ->
            Ok Fabric

        "making" ->
            Ok Making

        "ennobling" ->
            Ok Ennobling

        "distribution" ->
            Ok Distribution

        "use" ->
            Ok Use

        "eol" ->
            Ok EndOfLife

        _ ->
            Err ("Code étape inconnu: " ++ code)


toCodeString : Label -> String
toCodeString label =
    case label of
        Material ->
            "material"

        Spinning ->
            "spinning"

        Fabric ->
            "fabric"

        Making ->
            "making"

        Ennobling ->
            "ennobling"

        Distribution ->
            "distribution"

        Use ->
            "use"

        EndOfLife ->
            "eol"


toGitbookPath : Label -> Gitbook.Path
toGitbookPath label =
    case label of
        Material ->
            Gitbook.TextileMaterialAndSpinning

        Spinning ->
            Gitbook.TextileMaterialAndSpinning

        Fabric ->
            Gitbook.TextileFabric

        Ennobling ->
            Gitbook.TextileEnnobling

        Making ->
            Gitbook.TextileMaking

        Distribution ->
            Gitbook.TextileDistribution

        Use ->
            Gitbook.TextileUse

        EndOfLife ->
            Gitbook.TextileEndOfLife


decodeFromCode : Decoder Label
decodeFromCode =
    Decode.string
        |> Decode.andThen (fromCodeString >> DE.fromResult)


encode : Label -> Encode.Value
encode =
    toCodeString >> Encode.string
