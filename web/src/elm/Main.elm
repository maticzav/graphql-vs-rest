module Main exposing (Msg(..), main, update, view)

import Browser exposing (Document)
import Dict exposing (Dict)
import GraphQL.Object
import GraphQL.Object.TestPayload as TestPayload
import GraphQL.Query as Query
import Graphql.Http
import Graphql.Operation exposing (RootQuery)
import Graphql.SelectionSet exposing (SelectionSet, with)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as JD exposing (Decoder)
import Random exposing (Generator)
import Random.Char
import Random.Dict
import Random.String
import Task exposing (Task)
import Time
import Tuple


main =
    Browser.document
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


init : () -> ( Model, Cmd Msg )
init () =
    let
        model =
            Model 0 []
    in
    ( model, Cmd.none )



-- MODEL


type alias Model =
    { repetitions : Int
    , results : List Experiment
    }


type Experiment
    = RestTwoLayers { time : Int }
    | RestThreeLayers { time : Int }
    | GraphQLTwoLayers { time : Int }
    | GraphQLThreeLayers { time : Int }



-- UPDATE


type Msg
    = ChangeNumberOfRepetitions String
    | PerformExperiments
    | Results (List Experiment)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ experiments, currentTime } as model) =
    case msg of
        ChangeNumberOfRepetitions str ->
            case JD.decodeString JD.int str of
                Ok experimentSize ->
                    ( model
                    , Cmd.none
                      -- generateExperiment experimentSize
                    )

                Err _ ->
                    ( model, Cmd.none )

        PerformExperiments ->
            let
                performGraphQLExperiment =
                    \_ -> ( currentTime, Cmd.none )
            in
            ( model, Cmd.none )



-- Experiments


measureTask : Task x a -> Task x ( a, Int )
measureTask experiment =
    Time.now
        |> Task.andThen
            (\initialTime ->
                experiment
                    |> Task.andThen
                        (\result ->
                            Time.now
                                |> Task.map
                                    (\finalTime ->
                                        let
                                            time =
                                                Time.posixToMillis finalTime - Time.posixToMillis initialTime
                                        in
                                        ( result, time )
                                    )
                        )
            )



-- GraphQL


type alias GraphQLTwoLayerResponse =
    { test : GraphQLTwoLayerTestPayloadFirstLayer }


type alias GraphQLTwoLayerTestPayloadFirstLayer =
    { token : String
    , query : GraphQLTwoLayerQuery
    }


type alias GraphQLTwoLayerQuery =
    { test : GraphQLTwoLayerTestPayloadSecondLayer }


type alias GraphQLTwoLayerTestPayloadSecondLayer =
    { token : String }


graphqlTwoLayerExperiment : String -> Task (Graphql.Http.Error GraphQLTwoLayerResponse) GraphQLTwoLayerResponse
graphqlTwoLayerExperiment token =
    let
        testSelectionFirstLayer : SelectionSet GraphQLTwoLayerTestPayloadFirstLayer GraphQL.Object.TestPayload
        testSelectionFirstLayer =
            TestPayload.selection GraphQLTwoLayerTestPayloadFirstLayer
                |> with TestPayload.token
                |> with (TestPayload.query querySelection)

        querySelection : SelectionSet GraphQLTwoLayerQuery RootQuery
        querySelection =
            Query.selection GraphQLTwoLayerQuery
                |> with (Query.test { token = token } testSelectionSecondLayer)

        testSelectionSecondLayer : SelectionSet GraphQLTwoLayerTestPayloadSecondLayer GraphQL.Object.TestPayload
        testSelectionSecondLayer =
            TestPayload.selection GraphQLTwoLayerTestPayloadSecondLayer
                |> with TestPayload.token

        query : SelectionSet GraphQLTwoLayerResponse RootQuery
        query =
            Query.selection GraphQLTwoLayerResponse
                |> with (Query.test { token = token } testSelectionFirstLayer)
    in
    query
        |> Graphql.Http.queryRequest "http://localhost:4000"
        |> Graphql.Http.toTask


type alias GraphQLThreeLayerResponse =
    { test : GraphQLThreeLayerTestPayloadFirstLayer }


type alias GraphQLThreeLayerTestPayloadFirstLayer =
    { token : String
    , query : GraphQLThreeLayerQueryFirst
    }


type alias GraphQLThreeLayerQueryFirst =
    { test : GraphQLThreeLayerTestPayloadSecondLayer }


type alias GraphQLThreeLayerTestPayloadSecondLayer =
    { token : String
    , query : GraphQLThreeLayerQuerySecond
    }


type alias GraphQLThreeLayerQuerySecond =
    { test : GraphQLThreeLayerTestPayloadThirdLayer }


type alias GraphQLThreeLayerTestPayloadThirdLayer =
    { token : String }


graphqlThreeLayerExperiment : String -> Task (Graphql.Http.Error GraphQLThreeLayerResponse) GraphQLThreeLayerResponse
graphqlThreeLayerExperiment token =
    let
        testSelectionFirstLayer : SelectionSet GraphQLThreeLayerTestPayloadFirstLayer GraphQL.Object.TestPayload
        testSelectionFirstLayer =
            TestPayload.selection GraphQLThreeLayerTestPayloadFirstLayer
                |> with TestPayload.token
                |> with (TestPayload.query querySelectionFirstLayer)

        querySelectionFirstLayer : SelectionSet GraphQLThreeLayerQueryFirst RootQuery
        querySelectionFirstLayer =
            Query.selection GraphQLThreeLayerQueryFirst
                |> with (Query.test { token = token } testSelectionSecondLayer)

        testSelectionSecondLayer : SelectionSet GraphQLThreeLayerTestPayloadSecondLayer GraphQL.Object.TestPayload
        testSelectionSecondLayer =
            TestPayload.selection GraphQLThreeLayerTestPayloadSecondLayer
                |> with TestPayload.token
                |> with (TestPayload.query querySelectionSecondLayer)

        querySelectionSecondLayer : SelectionSet GraphQLThreeLayerQuerySecond RootQuery
        querySelectionSecondLayer =
            Query.selection GraphQLThreeLayerQuerySecond
                |> with (Query.test { token = token } testSelectionThirdLayer)

        testSelectionThirdLayer : SelectionSet GraphQLThreeLayerTestPayloadThirdLayer GraphQL.Object.TestPayload
        testSelectionThirdLayer =
            TestPayload.selection GraphQLThreeLayerTestPayloadThirdLayer
                |> with TestPayload.token

        query : SelectionSet GraphQLThreeLayerResponse RootQuery
        query =
            Query.selection GraphQLThreeLayerResponse
                |> with (Query.test { token = token } testSelectionFirstLayer)
    in
    query
        |> Graphql.Http.queryRequest "http://localhost:4000"
        |> Graphql.Http.toTask



-- REST


type alias RestResponse =
    { token : String
    , links : Dict String String
    }


restTwoLayersExperiment : String -> Task Http.Error RestResponse
restTwoLayersExperiment token =
    let
        uri =
            String.join "/" [ "http://localhost:2000", "test", token ]

        decodeLinks : Decoder (Dict String String)
        decodeLinks =
            JD.dict JD.string

        decodeResponse : Decoder RestResponse
        decodeResponse =
            JD.map2 RestResponse
                (JD.field "token" JD.string)
                (JD.field "links" decodeLinks)

        request =
            Http.get uri decodeResponse

        task =
            Http.toTask request
    in
    task
        |> Task.andThen (\_ -> task)


restThreeLayerExperiment : String -> Task Http.Error RestResponse
restThreeLayerExperiment token =
    let
        uri =
            String.join "/" [ "http://localhost:2000", "test", token ]

        decodeLinks : Decoder (Dict String String)
        decodeLinks =
            JD.dict JD.string

        decodeResponse : Decoder RestResponse
        decodeResponse =
            JD.map2 RestResponse
                (JD.field "token" JD.string)
                (JD.field "links" decodeLinks)

        request =
            Http.get uri decodeResponse

        task =
            Http.toTask request
    in
    task
        |> Task.andThen (\_ -> task)
        |> Task.andThen (\_ -> task)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    { title = "Rest vs GraphQL"
    , body = []
    }
