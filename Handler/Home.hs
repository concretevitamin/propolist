{-# LANGUAGE TupleSections, OverloadedStrings #-}
module Handler.Home where

import Import

import qualified Data.Text as T
import Data.ByteString.Lazy.Char8 as BL
import Control.Monad
import Control.Applicative
-- import Control.Arrow (&&&)

-- | Replace dollar signs by '\(' and '\)'. Dirty trick.
correctDollarSign :: String -> String
correctDollarSign s = helper s (0 :: Int)
    where helper "" _ = ""
          helper ('$':'$':x) _ = '$':(helper ('$':x) 3)
          helper ('$':x) 0 = '\\':'(':(helper x 1)
          helper ('$':x) 1 = '\\':')':(helper x 0)
          helper ('$':x) 2 = '$':(helper x 0)
          helper (a:x) 3 = a:(helper x 2)
          helper (a:x) n = a:(helper x n)

getHomeR :: Handler RepHtml
getHomeR = do
    (formWidget, formEnctype) <- generateFormPost thmForm
    let submission = Nothing :: Maybe Text
        handlerName = "getHomeR" :: Text
    defaultLayout $ do
        aDomId <- lift newIdent
        setTitle "PropoList"
        addStylesheet $ StaticR css_bootstrap_css
        addScriptRemote "http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML"
        $(widgetFile "homepage")


postHomeR :: Handler RepHtml
postHomeR = do
    ((result, formWidget), formEnctype) <- runFormPost thmForm
    let handlerName = "postHomeR" :: Text
        submission = case result of
            FormSuccess res -> Just $ Textarea . T.pack $ correctDollarSign $ T.unpack $ thmContent res
            _ -> Nothing

    defaultLayout $ do
        aDomId <- lift newIdent
        setTitle "PropoList"
        addStylesheet $ StaticR css_bootstrap_css
        addScriptRemote "http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML"
        $(widgetFile "homepage")

sampleForm :: Form Textarea
sampleForm = renderDivs $
    areq textareaField "New Proposition:" Nothing

thmForm :: Form Thm
thmForm = renderDivs $ Thm
          <$> areq (selectFieldList categories) "Category" Nothing
          <*> (unTextarea <$> areq textareaField "Content" Nothing)
          <*> (liftA unTextarea <$> aopt textareaField "Proof" Nothing)
          <*> aopt textField "Name" Nothing
          <*> (liftA textToSignature <$> aopt textField "Signature" Nothing)
          <*> aopt textField "Reference" Nothing
          <*> aopt textField "Note" Nothing
  where categories = Import.map (\ x -> ((T.pack . show) x, x)) $ [minBound .. maxBound]


textToSignature :: Text -> ThmSignature
textToSignature t = ThmSignature [] []

-- entryForm :: Form Thm
-- areqMaybe field fs mdef = fmap Just (areq field fs $ join mdef)

--entryForm :: RenderMessage master FormMessage =>
--         Maybe Thm -> Html ->
--         Form sub master Thm

--entryForm thm = renderDivs $ Thm
--    <$> areqMaybe textField "Type" (thmType <$> thm)
--    <*> areqMaybe textField "Content" (thmContent <$> thm)
--    <*> aopt textField "Proof" Nothing
--    <*> aopt textField "Name" Nothing
--    <*> aopt textField "Signature" Nothing
--    <*> aopt textField "Ref" Nothing
