module Main exposing (Msg(..), main, update, view)

import Browser exposing (Document)
import Color
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
import LineChart
import LineChart.Area as Area
import LineChart.Axis as Axis
import LineChart.Axis.Intersection as Intersection
import LineChart.Colors as Colors
import LineChart.Container as Container
import LineChart.Dots as Dots
import LineChart.Events as Events
import LineChart.Grid as Grid
import LineChart.Interpolation as Interpolation
import LineChart.Junk as Junk exposing (..)
import LineChart.Legends as Legends
import LineChart.Line as Line
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
            Model 0 Nothing
    in
    ( model, Cmd.none )



-- MODEL


type Model
    = Model Int (Maybe Experiments)


type alias Experiments =
    { restTwoLayersResults : List ( RestResponse, Int )
    , restThreeLayersResults : List ( RestResponse, Int )
    , graphqlTwoLayersResults : List ( GraphQLTwoLayerResponse, Int )
    , graphqlThreeLayersResults : List ( GraphQLThreeLayerResponse, Int )
    }



-- UPDATE


type Msg
    = ChangeNumberOfRepetitions String
    | PerformExperiments
    | GraphQLTwoLayerResults (Result (Graphql.Http.Error GraphQLTwoLayerResponse) (List ( GraphQLTwoLayerResponse, Int )))
    | GraphQLThreeLayerResults (Result (Graphql.Http.Error GraphQLThreeLayerResponse) (List ( GraphQLThreeLayerResponse, Int )))
    | RestTwoLayersResults (Result Http.Error (List ( RestResponse, Int )))
    | RestThreeLayersResults (Result Http.Error (List ( RestResponse, Int )))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ((Model repetitions experiments) as model) =
    case msg of
        ChangeNumberOfRepetitions str ->
            case JD.decodeString JD.int str of
                Ok newRepetitions ->
                    ( Model newRepetitions Nothing
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )

        PerformExperiments ->
            let
                graphQL2Layers =
                    performExperiment repetitions (graphqlTwoLayerExperiment "token")
                        |> Task.attempt GraphQLTwoLayerResults

                graphQL3Layers =
                    performExperiment repetitions (graphqlThreeLayerExperiment "token")
                        |> Task.attempt GraphQLThreeLayerResults

                rest2Layers =
                    performExperiment repetitions (restTwoLayersExperiment "token")
                        |> Task.attempt RestTwoLayersResults

                rest3Layers =
                    performExperiment repetitions (restThreeLayerExperiment "token")
                        |> Task.attempt RestThreeLayersResults
            in
            ( model
            , Cmd.batch [ graphQL2Layers, graphQL3Layers, rest2Layers, rest3Layers ]
            )

        GraphQLTwoLayerResults results ->
            case results of
                Ok newResults ->
                    let
                        newExperiments =
                            case experiments of
                                Just currentExperiments ->
                                    { currentExperiments | graphqlTwoLayersResults = newResults }

                                Nothing ->
                                    Experiments [] [] newResults []
                    in
                    ( Model repetitions (Just newExperiments), Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        GraphQLThreeLayerResults results ->
            case results of
                Ok newResults ->
                    let
                        newExperiments =
                            case experiments of
                                Just currentExperiments ->
                                    { currentExperiments | graphqlThreeLayersResults = newResults }

                                Nothing ->
                                    Experiments [] [] [] newResults
                    in
                    ( Model repetitions (Just newExperiments), Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        RestTwoLayersResults results ->
            case results of
                Ok newResults ->
                    let
                        newExperiments =
                            case experiments of
                                Just currentExperiments ->
                                    { currentExperiments | restTwoLayersResults = newResults }

                                Nothing ->
                                    Experiments newResults [] [] []
                    in
                    ( Model repetitions (Just newExperiments), Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        RestThreeLayersResults results ->
            case results of
                Ok newResults ->
                    let
                        newExperiments =
                            case experiments of
                                Just currentExperiments ->
                                    { currentExperiments | restThreeLayersResults = newResults }

                                Nothing ->
                                    Experiments [] newResults [] []
                    in
                    ( Model repetitions (Just newExperiments), Cmd.none )

                Err _ ->
                    ( model, Cmd.none )



-- Experiments
-- performExperiments :


performExperiment : Int -> Task x a -> Task x (List ( a, Int ))
performExperiment repetitions experiment =
    Task.sequence (List.repeat repetitions (measureTask experiment))


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
view ((Model repetitions experiments) as model) =
    { title = "Rest vs GraphQL"
    , body =
        [ div []
            [ input [ onInput ChangeNumberOfRepetitions, placeholder "N" ] []
            , button [ onClick PerformExperiments ] [ text "Perform experiments" ]
            ]
        , div []
            (case experiments of
                Just currentExperiments ->
                    [ chart currentExperiments ]

                Nothing ->
                    [ text "Run experiments!" ]
            )
        ]
    }


chart : Experiments -> Html Msg
chart experiments =
    let
        normaliseExperiments : List ( a, Int ) -> List ( Float, Float )
        normaliseExperiments exs =
            List.indexedMap (\i ( _, v ) -> ( toFloat i, toFloat v )) exs
    in
    LineChart.viewCustom
        { x = Axis.default 700 "Sample" Tuple.first
        , y = Axis.default 450 "Delay" Tuple.second
        , container = Container.styled "line-chart-1" [ ( "font-family", "monospace" ) ]
        , interpolation = Interpolation.default
        , intersection = Intersection.default
        , legends = Legends.default
        , events = Events.default
        , junk = Junk.default
        , grid = Grid.default
        , area = Area.default
        , line = Line.default
        , dots = Dots.custom (Dots.full 2.0)
        }
        [ LineChart.line Color.blue Dots.circle "GraphQL Two Layers" (normaliseExperiments experiments.graphqlTwoLayersResults)
        , LineChart.line Color.purple Dots.circle "GraphQL Three Layers" (normaliseExperiments experiments.graphqlThreeLayersResults)
        , LineChart.line Color.yellow Dots.circle "Rest Two Layers" (normaliseExperiments experiments.restTwoLayersResults)
        , LineChart.line Color.green Dots.circle "Rest Three Layers" (normaliseExperiments experiments.restThreeLayersResults)
        ]
