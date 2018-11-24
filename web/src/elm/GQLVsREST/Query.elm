-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module GQLVsREST.Query exposing (TestRequiredArguments, selection, test)

import GQLVsREST.InputObject
import GQLVsREST.Interface
import GQLVsREST.Object
import GQLVsREST.Scalar
import GQLVsREST.Union
import Graphql.Field as Field exposing (Field)
import Graphql.Internal.Builder.Argument as Argument exposing (Argument)
import Graphql.Internal.Builder.Object as Object
import Graphql.Internal.Encode as Encode exposing (Value)
import Graphql.Operation exposing (RootMutation, RootQuery, RootSubscription)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet exposing (SelectionSet)
import Json.Decode as Decode exposing (Decoder)


{-| Select fields to build up a top-level query. The request can be sent with
functions from `Graphql.Http`.
-}
selection : (a -> constructor) -> SelectionSet (a -> constructor) RootQuery
selection constructor =
    Object.selection constructor


type alias TestRequiredArguments =
    { token : String }


{-|

  - token -

-}
test : TestRequiredArguments -> SelectionSet decodesTo GQLVsREST.Object.TestPayload -> Field decodesTo RootQuery
test requiredArgs object_ =
    Object.selectionField "test" [ Argument.required "token" requiredArgs.token Encode.string ] object_ identity
