port module Ports exposing (..)

port applyfilter : (String, String) -> Cmd msg

port gotresult : (String -> msg) -> Sub msg
port goterror : (String -> msg) -> Sub msg
