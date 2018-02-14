import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Platform.Sub as Sub
import Json.Encode
import Array exposing (Array, get, set, push, length)

import Ports exposing (..)


main =
  Html.programWithFlags
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }


-- MODEL

type alias Model =
  { tab : Tab
  , input : String
  , filter : String
  , output : Result String String
  }

type Tab = Input | View


init : {input : String, filter : String} -> (Model, Cmd Msg)
init {input, filter} =
  let model =
    { tab = View
    , input = input
    , filter = filter
    , output = Ok ""
    }
  in
    ( model
    , applyfilter (input, filter)
    )


-- UPDATE

type Msg
  = SelectTab Tab
  | SetInput String
  | SetFilter String
  | GotResult String
  | GotError String

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    SelectTab t -> ({ model | tab = t }, Cmd.none)
    SetInput v ->
      ( { model | input = v }
      , applyfilter (v, model.filter)
      )
    SetFilter v ->
      ( { model | filter = v }
      , applyfilter (model.input, v)
      )
    GotResult v ->
      ( { model | output = Ok v }
      , Cmd.none
      )
    GotError err ->
      ( { model | output = Err err }
      , Cmd.none
      )


-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
    [ gotresult GotResult
    , goterror GotError
    ]


-- VIEW

view : Model -> Html Msg
view model =
  div []
    [ div [ class "tabs is-centered is-boxed" ]
      [ ul []
        [ li [ class <| if model.tab == Input then "is-active" else "" ]
          [ a [ onClick (SelectTab Input) ]
            [ text "Input"
            ]
          ]
        , li [ class <| if model.tab == View then "is-active" else "" ]
          [ a [ onClick (SelectTab View) ]
            [ text "View"
            ]
          ]
        ]
      ]
    , case model.tab of
      Input ->
        div [ id "input" ]
          [ textarea [ class "textarea", onInput SetInput ] [ text model.input ]
          ]
      View ->
        div [ id "view", class "panel" ]
          [ input [ class "input", onInput SetFilter, value model.filter ] []
          , div [ class "box" ]
            [ case model.output of
              Ok json -> text json
              Err err -> div [ class "error" ] [ text err ]
            ]
          ]
    ]
    
