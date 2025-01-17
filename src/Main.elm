module Main exposing (main)

import Browser
import Html as H
import User.Age as Age exposing (Age)
import User.DisplayName as DisplayName exposing (DisplayName)
import User.Email as Email exposing (Email)
import Utils.State as State
import Views.Form as Form


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        , onUrlChange = \_ -> NoOp
        , onUrlRequest = \_ -> NoOp
        }


init : flags -> url -> key -> ( Model, Cmd Msg )
init _ _ _ =
    ( emptyModel, Cmd.none )



-------------------------------------------------------
---- MODEL --------------------------------------------
-------------------------------------------------------
-- String means an unparsed value, just raw input from the user. These
-- strings will not be used except to be parsed. When they are parsed they
-- are parsed into their respective type, so EmailAddress means the user input
-- has been parsed, while String means it hasn't. Strings are used here for
-- convenience, and because type safety doesn't actually get us enough to
-- justify the complexity, in our opinion.


type alias Model =
    { email : String
    , emailError : String
    , displayName : String
    , displayNameError : String
    , age : Maybe Int
    , ageError : String
    }



-- Empty string is invalid, so Maybe is only a more explicit version of empty
-- string that otherwise gets us nothing, so it's not worth adding the
-- complexity of a Maybe just to be explicit.


emptyModel : Model
emptyModel =
    { email = ""
    , emailError = ""
    , displayName = ""
    , displayNameError = ""
    , age = Nothing
    , ageError = ""
    }


type alias User =
    { email : Email
    , displayName : DisplayName
    , age : Age
    }



-------------------------------------------------------
---- MSG ----------------------------------------------
-------------------------------------------------------


type Msg
    = NoOp
    | ResetClicked
    | SubmitClicked
    | EmailUpdated String
    | EmailBlurred
    | DisplayNameUpdated String
    | DisplayNameBlurred
    | AgeUpdated (Maybe Int)
    | AgeBlurred



-------------------------------------------------------
---- UPDATE -------------------------------------------
-------------------------------------------------------


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ResetClicked ->
            ( emptyModel, Cmd.none )

        SubmitClicked ->
            let
                {-
                   The second parameter to this tuple will be `Maybe User`.
                   You can decide to do whatever you want with this, maybe you
                   serialize it to json and submit a POST request?
                -}
                ( updatedModel, _ ) =
                    Tuple.mapSecond (Debug.log "parsedUserr") (parseUser model)
            in
            ( updatedModel, Cmd.none )

        EmailUpdated email ->
            ( { model | email = email }
            , Cmd.none
            )

        EmailBlurred ->
            ( Tuple.first (parseEmail model)
            , Cmd.none
            )

        DisplayNameUpdated displayName ->
            ( { model | displayName = displayName }
            , Cmd.none
            )

        DisplayNameBlurred ->
            ( Tuple.first (parseDisplayName model)
            , Cmd.none
            )

        AgeUpdated age ->
            ( { model | age = age }
            , Cmd.none
            )

        AgeBlurred ->
            ( Tuple.first (parseAge model)
            , Cmd.none
            )

        NoOp ->
            ( model, Cmd.none )


parseEmail : Model -> ( Model, Maybe Email )
parseEmail model =
    case Email.make model.email of
        Err error ->
            let
                description =
                    case error of
                        Email.IsEmpty ->
                            "Email is required."

                        Email.IsInvalid ->
                            "Email is invalid."
            in
            ( { model | emailError = description }
            , Nothing
            )

        Ok email ->
            ( { model | emailError = "" }
            , Just email
            )


parseDisplayName : Model -> ( Model, Maybe DisplayName )
parseDisplayName model =
    case DisplayName.make model.displayName of
        Err error ->
            let
                description =
                    case error of
                        DisplayName.IsEmpty ->
                            "Display Name is required."

                        DisplayName.IsLongerThan maxLength ->
                            "Display Name is longer than " ++ String.fromInt maxLength ++ " characters."
            in
            ( { model | displayNameError = description }
            , Nothing
            )

        Ok displayName ->
            ( { model | displayNameError = "" }
            , Just displayName
            )


parseAge : Model -> ( Model, Maybe Age )
parseAge model =
    case Maybe.map Age.make model.age of
        Nothing ->
            ( { model | ageError = "Age is required." }
            , Nothing
            )

        Just (Err error) ->
            let
                description =
                    case error of
                        Age.IsLessThanMinAge minAge ->
                            "Age must be greater than or equal to " ++ String.fromInt minAge ++ "."

                        Age.IsGreaterThanMaxAge maxAge ->
                            "Age must be less than or equal to " ++ String.fromInt maxAge ++ "."
            in
            ( { model | ageError = description }
            , Nothing
            )

        Just (Ok age) ->
            ( { model | ageError = "" }
            , Just age
            )


parseUser : Model -> ( Model, Maybe User )
parseUser =
    {-
       This is the magic! Allows us to correct the error for every field while
       still safely parsing values that may fail.

       If this was converted to Haskell, it would be:
       User <$> parseEmail <*> parseDisplayName <*> parseAge
    -}
    State.mapMaybe User parseEmail
        |> State.applyMaybe parseDisplayName
        |> State.applyMaybe parseAge



-------------------------------------------------------
---- VIEW ---------------------------------------------
-------------------------------------------------------


view : Model -> Browser.Document Msg
view model =
    { title = "Elm Form Validation Example"
    , body =
        [ H.main_ []
            [ H.h1 [] [ H.text "Example Form" ]
            , Form.form { id = "example-form", onSubmit = SubmitClicked, onReset = ResetClicked }
                [ Form.textInput
                    { id = "email"
                    , label = "Email"
                    , value = model.email
                    , error = model.emailError
                    , onInput = EmailUpdated
                    , onBlur = EmailBlurred
                    }
                , Form.textInput
                    { id = "displayName"
                    , label = "Display Name"
                    , value = model.displayName
                    , error = model.displayNameError
                    , onInput = DisplayNameUpdated
                    , onBlur = DisplayNameBlurred
                    }
                , Form.numberInput
                    { id = "age"
                    , label = "Age"
                    , value = model.age
                    , error = model.ageError
                    , onInput = AgeUpdated
                    , onBlur = AgeBlurred
                    }
                ]
            ]
        ]
    }
