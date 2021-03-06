-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module GraphQL.Object.TestPayload exposing (query, selection, token)

import GraphQL.InputObject
import GraphQL.Interface
import GraphQL.Object
import GraphQL.Scalar
import GraphQL.Union
import Graphql.Field as Field exposing (Field)
import Graphql.Internal.Builder.Argument as Argument exposing (Argument)
import Graphql.Internal.Builder.Object as Object
import Graphql.Internal.Encode as Encode exposing (Value)
import Graphql.Operation exposing (RootMutation, RootQuery, RootSubscription)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet exposing (SelectionSet)
import Json.Decode as Decode


{-| Select fields to build up a SelectionSet for this object.
-}
selection : (a -> constructor) -> SelectionSet (a -> constructor) GraphQL.Object.TestPayload
selection constructor =
    Object.selection constructor


{-| -}
token : Field String GraphQL.Object.TestPayload
token =
    Object.fieldDecoder "token" [] Decode.string


{-| -}
query : SelectionSet decodesTo RootQuery -> Field decodesTo GraphQL.Object.TestPayload
query object_ =
    Object.selectionField "query" [] object_ identity
