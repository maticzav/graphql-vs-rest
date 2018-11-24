module Main exposing (Msg(..), main, update, view)

import Browser exposing (Document)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Task
import Time


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
            Model 0 (NotStarted 0) (NotStarted 10)

        cmds =
            Cmd.batch [ Task.perform Tick Time.now ]
    in
    ( model, Cmd.none )



-- MODEL


type Experiment a
    = NotStarted Int
    | Performing a Int
    | Completed a


type GraphQLExperiment
    = GraphQLExperiment String Int


type RestExperiment
    = RestExperiment String


type alias Model =
    { time : Int
    , graphql : Experiment Bool
    , rest : Experiment Bool
    }



-- UPDATE


type Msg
    = Tick Time.Posix
    | ChangeNumberOfRepetitions Int
    | PerformExperiment


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick posixTime ->
            ( { model | time = Time.posixToMillis posixTime }
            , Cmd.none
            )

        ChangeNumberOfRepetitions int ->
            ( model, Cmd.none )

        PerformExperiment ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Time.every 1 Tick



-- VIEW


view : Model -> Document Msg
view model =
    { title = "Rest vs GraphQL"
    , body = []
    }
