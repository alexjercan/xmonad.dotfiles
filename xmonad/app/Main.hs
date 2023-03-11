module Main (main) where

  -- Base
import           System.Exit
import           System.IO                           (hPutStrLn)
import           XMonad
import qualified XMonad.StackSet                     as W

    -- Actions
import           XMonad.Actions.CopyWindow           (kill1, killAllOtherCopies)
import           XMonad.Actions.CycleWS              (WSType (..), moveTo,
                                                      shiftTo)
import           XMonad.Actions.MouseResize
import           XMonad.Actions.Promote
import           XMonad.Actions.RotSlaves            (rotAllDown, rotSlavesDown)
import qualified XMonad.Actions.Search               as S
import           XMonad.Actions.WithAll              (killAll, sinkAll)

    -- Data
import qualified Data.Map                            as M
import           Data.Monoid

    -- Hooks
import           XMonad.Config.Desktop
import           XMonad.Hooks.DynamicLog             (PP (..), dynamicLogWithPP,
                                                      shorten, wrap,
                                                      xmobarColor, xmobarPP,
                                                      dynamicLogString,
                                                      xmonadPropLog)
import           XMonad.Hooks.EwmhDesktops
import           XMonad.Hooks.FadeInactive
import           XMonad.Hooks.ManageDocks            (ToggleStruts (..),
                                                      avoidStruts,
                                                      docksEventHook,
                                                      manageDocks)
import           XMonad.Hooks.ManageHelpers          (doFullFloat,
                                                      isFullscreen,
                                                      doCenterFloat)
import           XMonad.Hooks.ServerMode
import           XMonad.Hooks.WorkspaceHistory

    -- Layouts
import           XMonad.Layout.GridVariants (Grid(Grid))
import           XMonad.Layout.ResizableTile
import           XMonad.Layout.SimplestFloat

    -- Layouts modifiers
import           XMonad.Layout.LayoutModifier
import           XMonad.Layout.LimitWindows          (decreaseLimit,
                                                      increaseLimit,
                                                      limitWindows)
import           XMonad.Layout.MultiToggle           (EOT (EOT), mkToggle, (??))
import qualified XMonad.Layout.MultiToggle           as MT (Toggle (..))
import           XMonad.Layout.MultiToggle.Instances (StdTransformers (NBFULL, NOBORDERS))
import           XMonad.Layout.Renamed               (Rename (Replace), renamed)
import           XMonad.Layout.Spacing
import qualified XMonad.Layout.ToggleLayouts         as T (ToggleLayout (Toggle),
                                                           toggleLayouts)
import           XMonad.Layout.WindowArranger        (WindowArrangerMsg (..),
                                                      windowArrange)

    -- Prompt
import           Control.Arrow                       (first)
import           XMonad.Prompt
import           XMonad.Prompt.FuzzyMatch
import           XMonad.Prompt.Man
import           XMonad.Prompt.Shell                 (shellPrompt)
import           XMonad.Prompt.Ssh
import           XMonad.Prompt.XMonad

   -- Utilities
import           XMonad.Util.EZConfig                (additionalKeysP)
import           XMonad.Util.Run                     (spawnPipe)
import           XMonad.Util.SpawnOnce
import           XMonad.Util.Cursor
-- import           XMonad.Wallpaper
import XMonad.Layout.NoBorders (smartBorders)

myBrowser :: String
myBrowser = "brave-browser"

myFileExplorer :: String
myFileExplorer = "thunar"

myScreenshoter :: String
myScreenshoter = "scrot -e 'mv $f ~/Pictures/Screenshots/'"

myShell :: String
myShell = "zsh"

myFont :: String
myFont = "xft:monospace:pixelsize=11"

myModMask :: KeyMask
myModMask = mod4Mask       -- Sets modkey to super/windows key

myTerminal :: String
myTerminal = "kitty"   -- Sets default terminal

myBorderWidth :: Dimension
myBorderWidth = 2         -- Sets border width for windows

myNormalBlack = "#000000"
myNormalRed = "#ff5555"
myNormalGreen = "#50fa7b"
myNormalYellow = "#f1fa8c"
myNormalBlue = "#bd93f9"
myNormalMagenta = "#ff79c6"
myNormalCyan = "#8be9fd"
myNormalWhite = "#bfbfbf"
myBrightBlack = "#4d4d4d"
myBrightRed = "#ff6e67"
myBrightGreen = "#5af78e"
myBrightYellow = "#f4f99d"
myBrightBlue = "#caa9fa"
myBrightMagenta = "#ff92d0"
myBrightCyan = "#9aedfe"
myBrightWhite = "#e6e6e6"
myDimBlack = "#14151b"
myDimRed = "#ff2222"
myDimGreen = "#1ef956"
myDimYellow = "#ebf85b"
myDimBlue = "#4d5b86"
myDimMagenta = "#ff46b0"
myDimCyan = "#59dffc"
myDimWhite = "#e6e6d1"

myNormColor :: String
myNormColor = myDimBlack -- Border color of normal windows

myFocusColor :: String
myFocusColor  = myBrightBlack -- Border color of focused windows

altMask :: KeyMask
altMask = mod1Mask        -- Setting this for use in xprompts

windowCount :: X (Maybe String)
windowCount = gets $ Just . show . length . W.integrate' . W.stack . W.workspace . W.current . windowset

nonEmptyWS :: WSType
nonEmptyWS = WSIs (return (\ws -> not (null (W.integrate' $ W.stack ws))))

myStartupHook :: X ()
myStartupHook = do
          setDefaultCursor xC_left_ptr
          spawnOnce "picom &"
          spawnOnce "nitrogen --random --restore &"
          spawnOnce "trayer --edge top --align right --widthtype request --padding 6 --SetDockType true --SetPartialStrut true --expand true --monitor 0 --transparent true --alpha 255 --height 22 &"
          spawnOnce "nm-applet &"
          spawnOnce "blueman-applet &"

myXPConfig :: XPConfig
myXPConfig = def
      { font                = myFont
      , bgColor             = myDimBlack
      , fgColor             = myDimWhite
      , bgHLight            = myBrightBlue
      , fgHLight            = myDimBlack
      , borderColor         = myDimBlack
      , promptBorderWidth   = 0
      , promptKeymap        = myXPKeymap
      , position            = Top
      , height              = 28
      , historySize         = 256
      , historyFilter       = id
      , defaultText         = []
      , autoComplete        = Nothing -- Just 1000 doesen't seem to work
      , showCompletionOnTab = False
      , searchPredicate     = fuzzyMatch
      , alwaysHighlight     = True
      , maxComplRows        = Nothing      -- set to Just 5 for 5 rows
      }

promptList :: [(String, XPConfig -> X ())]
promptList = [ ("m", manPrompt)          -- manpages prompt
             , ("s", sshPrompt)          -- ssh prompt
             , ("x", xmonadPrompt)       -- xmonad prompt
             ]

myXPKeymap :: M.Map (KeyMask,KeySym) (XP ())
myXPKeymap = M.fromList $
     map (first $ (,) controlMask)   -- control + <key>
     [ (xK_z, killBefore)            -- kill line backwards
     , (xK_k, killAfter)             -- kill line forwards
     , (xK_a, startOfLine)           -- move to the beginning of the line
     , (xK_e, endOfLine)             -- move to the end of the line
     , (xK_m, deleteString Next)     -- delete a character foward
     , (xK_b, moveCursor Prev)       -- move cursor forward
     , (xK_f, moveCursor Next)       -- move cursor backward
     , (xK_BackSpace, killWord Prev) -- kill the previous word
     , (xK_y, pasteString)           -- paste a string
     , (xK_g, quit)                  -- quit out of prompt
     , (xK_bracketleft, quit)
     ]
     ++
     map (first $ (,) altMask)       -- meta key + <key>
     [ (xK_BackSpace, killWord Prev) -- kill the prev word
     , (xK_f, moveWord Next)         -- move a word forward
     , (xK_b, moveWord Prev)         -- move a word backward
     , (xK_d, killWord Next)         -- kill the next word
     , (xK_n, moveHistory W.focusUp')   -- move up thru history
     , (xK_p, moveHistory W.focusDown') -- move down thru history
     ]
     ++
     map (first $ (,) 0) -- <key>
     [ (xK_Return, setSuccess True >> setDone True)
     , (xK_KP_Enter, setSuccess True >> setDone True)
     , (xK_BackSpace, deleteString Prev)
     , (xK_Delete, deleteString Next)
     , (xK_Left, moveCursor Prev)
     , (xK_Right, moveCursor Next)
     , (xK_Home, startOfLine)
     , (xK_End, endOfLine)
     , (xK_Down, moveHistory W.focusUp')
     , (xK_Up, moveHistory W.focusDown')
     , (xK_Escape, quit)
     ]

searchList :: [(String, S.SearchEngine)]
searchList = [ ("d", S.duckduckgo)
             , ("g", S.google)
             , ("h", S.hoogle)
             , ("i", S.images)
             , ("t", S.thesaurus)
             , ("v", S.vocabulary)
             , ("b", S.wayback)
             , ("w", S.wikipedia)
             , ("y", S.youtube)
             , ("z", S.amazon)
             ]

mySpacing :: Integer -> l a -> XMonad.Layout.LayoutModifier.ModifiedLayout Spacing l a
mySpacing i = spacingRaw False (Border i i i i) True (Border i i i i) True

tall     = renamed [Replace "tall"]
           $ limitWindows 12
           $ mySpacing 8
           $ ResizableTall 1 (3/100) (1/2) []
grid     = renamed [Replace "grid"]
           $ limitWindows 12
           $ mySpacing 0
           $ Grid (16/10)
floats   = renamed [Replace "floats"]
           $ limitWindows 20 simplestFloat

-- The layout hook
myLayoutHook = avoidStruts $ mouseResize $ windowArrange $ T.toggleLayouts floats $
               mkToggle (NBFULL ?? NOBORDERS ?? EOT) myDefaultLayout
             where
                 myDefaultLayout = grid ||| tall ||| floats ||| smartBorders Full

xmobarEscape :: String -> String
xmobarEscape = concatMap doubleLts
  where
        doubleLts '<' = "<<"
        doubleLts x   = [x]

myClickableText :: String -> String -> String
myClickableText xKeyCode action = "<action=xdotool key " ++ xKeyCode ++ "> " ++ action ++ " </action>"

myWorkspaces :: [String]
myWorkspaces = map (clickable . xmobarEscape) ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
  where
        clickable l = myClickableText ("super+" ++ l) l

myManageHook :: XMonad.Query (Data.Monoid.Endo WindowSet)
myManageHook = composeAll
            [ className =? "Steam" --> doShift ( myWorkspaces !! 8 )
            , className =? "Steam" --> doFloat
            , className =? "discord" --> doShift ( myWorkspaces !! 7 )
            , className =? "discord" --> doFloat
            , className =? "Microsoft Teams - Preview" --> doShift ( myWorkspaces !! 6 )
            , className =? "Gimp" --> doShift ( myWorkspaces !! 3 )
            , className =? "Gimp" --> doFloat
            , className =? "Pavucontrol" --> doCenterFloat
            , className =? "Org.gnome.Weather" --> doCenterFloat
            , className =? "Gnome-calendar" --> doCenterFloat
            , className =? "Blueman-manager" --> doCenterFloat
            ]

myLogHook :: X ()
myLogHook = fadeInactiveLogHook fadeAmount
    where fadeAmount = 1.0

myKeys :: [(String, X ())]
myKeys =
    -- Xmonad
        [ ("M-C-r", spawn "xmonad --recompile")      -- Recompiles xmonad
        , ("M-S-r", spawn "xmonad --restart")        -- Restarts xmonad
        , ("M-S-q", io exitSuccess)                  -- Quits xmonad

    -- Open applications
        , ("M-<Return>", spawn (myTerminal ++ " -e " ++ myShell))
        , ("M-b", spawn myBrowser)
        , ("M-n", spawn myFileExplorer)
        , ("M-S-s", spawn myScreenshoter)

    -- Run Prompt
        , ("M-S-<Return>", shellPrompt myXPConfig)   -- Shell Prompt

    -- Windows
        , ("M-S-c", kill1)                           -- Kill the currently focused client
        , ("M-S-a", killAll)                         -- Kill all windows on current workspace

    -- Floating windows
        , ("M-f", sendMessage (T.Toggle "floats"))       -- Toggles my 'floats' layout
        , ("M-<Delete>", withFocused $ windows . W.sink) -- Push floating window back to tile
        , ("M-S-<Delete>", sinkAll)                      -- Push ALL floating windows to tile

    -- Windows navigation
        , ("M-m", windows W.focusMaster)     -- Move focus to the master window
        , ("M-j", windows W.focusDown)       -- Move focus to the next window
        , ("M-k", windows W.focusUp)         -- Move focus to the prev window
        , ("M-S-j", windows W.swapDown)      -- Swap focused window with next window
        , ("M-S-k", windows W.swapUp)        -- Swap focused window with prev window
        , ("M-<Backspace>", promote)         -- Moves focused window to master, others maintain order
        , ("M-S-<Tab>", rotSlavesDown)      -- Rotate all windows except master and keep focus in place
        , ("M-C-<Tab>", rotAllDown)         -- Rotate all the windows in the current stack
        , ("M-C-s", killAllOtherCopies)

        -- Layouts
        , ("M-<Tab>", sendMessage NextLayout)                -- Switch to next layout
        , ("M-C-M1-<Up>", sendMessage Arrange)
        , ("M-C-M1-<Down>", sendMessage DeArrange)
        , ("M-<Space>", sendMessage (MT.Toggle NBFULL) >> sendMessage ToggleStruts) -- Toggles noborder/full
        , ("M-S-<Space>", sendMessage ToggleStruts)         -- Toggles struts
        , ("M-S-n", sendMessage $ MT.Toggle NOBORDERS)      -- Toggles noborder
        , ("M-<KP_Multiply>", sendMessage (IncMasterN 1))   -- Increase number of clients in master pane
        , ("M-<KP_Divide>", sendMessage (IncMasterN (-1)))  -- Decrease number of clients in master pane
        , ("M-S-<KP_Multiply>", increaseLimit)              -- Increase number of windows
        , ("M-S-<KP_Divide>", decreaseLimit)                -- Decrease number of windows

        , ("M-h", sendMessage Shrink)                       -- Shrink horiz window width
        , ("M-l", sendMessage Expand)                       -- Expand horiz window width
        , ("M-C-j", sendMessage MirrorShrink)               -- Shrink vert window width
        , ("M-C-k", sendMessage MirrorExpand)               -- Exoand vert window width

    -- Workspaces
        , ("M-S-<KP_Add>", shiftTo Next nonNSP >> moveTo Next nonNSP)       -- Shifts focused window to next ws
        , ("M-S-<KP_Subtract>", shiftTo Prev nonNSP >> moveTo Prev nonNSP)  -- Shifts focused window to prev ws
        , ("M1-<Tab>", moveTo Next nonEmptyWS)
        , ("M1-S-<Tab>", moveTo Prev nonEmptyWS)

    -- Fn
        , ("<XF86AudioMute>", spawn "pactl set-sink-mute @DEFAULT_SINK@ toggle")
        , ("<XF86AudioLowerVolume>", spawn "pactl set-sink-volume @DEFAULT_SINK@ -2% && pactl set-sink-mute @DEFAULT_SINK@ false")
        , ("<XF86AudioRaiseVolume>", spawn "pactl set-sink-volume @DEFAULT_SINK@ +2% && pactl set-sink-mute @DEFAULT_SINK@ false")
        , ("<XF86MonBrightnessUp>", spawn "lux -a 10%")
        , ("<XF86MonBrightnessDown>", spawn "lux -s 10%")
        ]
        ++ [("M-s " ++ k, S.selectSearchBrowser myBrowser f) | (k,f) <- searchList ]
        ++ [("M-S-p " ++ k, S.promptSearchBrowser myXPConfig myBrowser f) | (k,f) <- searchList ]
        ++ [("M-S-p " ++ k, f myXPConfig) | (k,f) <- promptList ]
          where nonNSP = WSIs (return (\ws -> W.tag ws /= "nsp"))

main:: IO ()
main = do
    _ <- spawnPipe "xmobar"
    xmonad $ ewmh desktopConfig
        { manageHook = (isFullscreen --> doFullFloat) <+>  myManageHook <+> manageDocks
        , handleEventHook    = fullscreenEventHook
                               <+> serverModeEventHookCmd
                               <+> serverModeEventHook
                               <+> serverModeEventHookF "XMONAD_PRINT" (io . putStrLn)
                               <+> docksEventHook
        , modMask            = myModMask
        , terminal           = myTerminal
        , startupHook        = myStartupHook
        , layoutHook         = myLayoutHook
        , workspaces         = myWorkspaces
        , borderWidth        = myBorderWidth
        , normalBorderColor  = myNormColor
        , focusedBorderColor = myFocusColor
        , logHook = dynamicLogString xmobarPP
                         { ppCurrent = xmobarColor myBrightCyan "" . wrap "[" "]"
                         , ppHidden = xmobarColor myDimCyan "" . wrap "*" ""
                         , ppHiddenNoWindows = xmobarColor myDimWhite ""
                         , ppTitle = xmobarColor myDimWhite "" . shorten 60
                         , ppExtras  = [windowCount]
                         , ppOrder  = \(ws:l:t:ex) -> [ws,l]++ex++[t]
                         } >>= xmonadPropLog
        } `additionalKeysP` myKeys


