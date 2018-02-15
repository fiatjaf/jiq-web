import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Platform.Sub as Sub
import Json.Encode
import String exposing (trim, startsWith)
import SyntaxHighlight exposing (javascript, toBlockHtml)

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
  , url : Maybe String
  , filter : String
  , output : Result String String
  }

type Tab = Input | View


init : {input : String, filter : String} -> (Model, Cmd Msg)
init {input, filter} =
  let model =
    { tab = View
    , input = input
    , url = Nothing
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
  | SetInput Bool String
  | InputURLResult (Result Http.Error String)
  | SetFilter String
  | GotResult String
  | GotError String

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    SelectTab t -> ({ model | tab = t }, Cmd.none)
    SetInput manual v ->
      if v |> startsWith "http"
      then
        ( { model | url = Just <| trim v }
        , Http.getString (trim v)
          |> Http.send InputURLResult
        )
      else
        ( { model | input = v, url = if manual then Nothing else model.url }
        , applyfilter (model.input, v)
        )
    InputURLResult res ->
      case res of
        Ok json -> update (SetInput False json) model
        Err err -> update (SetInput False (toString err)) model
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
            [ text "JSON Input"
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
          [ div [ class "container has-text-centered" ]
            [ text <| Maybe.withDefault "" model.url
            ]
          , textarea [ class "textarea", onInput (SetInput True) ] [ text model.input ]
          ]
      View ->
        div [ id "view", class "panel" ]
          [ input [ class "input", onInput SetFilter, value model.filter ] []
          , div [ class "box" ]
            [ case model.output of
              Ok json -> div []
                [ javascript json
                  |> Result.map (toBlockHtml Nothing)
                  |> Result.withDefault (text json)
                ]
              Err err -> div [ class "error" ] [ text err ]
            ]
          ]
    ]
    
