using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Simulation }


cursor_info := class:

    var LastCameraRotation : rotation = rotation{}
    var CursorX : float = 0.0
    var CursorY : float = 0.0
    var LastPitch : float = 0.0

    CreativeObj : creative_object_interface
    RemoveUIEvent : event(player)

    Sensitivity : float = 2.0
    ScreenSize : vector2 = vector2{X:=1920.0,Y:=1080.0}

    HandleCursorMenu(Player : player, CursorMenu : cursor_menu)<suspends>:void=
        CursorMenu.Init(Player)
        if:
            FC := Player.GetFortCharacter[]
        then:
            CursorMenu.AddToPlayer(Player, false)
            FC.PutInStasis(stasis_args{AllowTurning:=true})
            race:
                AwaitRemoval(Player)
                loop:
                    NewPos := GetCursorPosition(FC)
                    CursorMenu.MoveCursor(NewPos)
                    Sleep(0.0)
            CursorMenu.RemoveFromPlayer(Player)
            FC.ReleaseFromStasis()

    AwaitRemoval(Player : player)<suspends>:void=
        race:
            loop:
                PlayerRemoved := RemoveUIEvent.Await()
                if:
                    PlayerRemoved = Player
                then:
                    break
            loop:
                PlayerRemoved := CreativeObj.GetPlayspace().PlayerRemovedEvent().Await()
                if:
                    PlayerRemoved = Player
                then:
                    break

    GetCursorPosition(FC : fort_character): vector2 =
        CurrentRotation:= FC.GetViewRotation()
        YawDelta:= GetYawDelta(CurrentRotation, LastCameraRotation)
        CurrentPitch:= GetPitchFromRotation(CurrentRotation)
 
        var PitchDelta: float = 0.0
        if. CurrentPitch <> LastPitch then:
            set PitchDelta = CurrentPitch - LastPitch
            set LastPitch = CurrentPitch
 
        set CursorX = Clamp(CursorX + (YawDelta * (ScreenSize.X / 360.0) * Sensitivity), 0.0, ScreenSize.X)
        set CursorY = Lerp(0.0, ScreenSize.Y, (((CurrentPitch + 90.0) * 2.0) / 180.0))
 
        set LastCameraRotation = CurrentRotation
 
        CurrentPos:= vector2{X:= CursorX, Y:= CursorY}

        return CurrentPos

    GetYawDelta(Current: rotation, Last: rotation): float =
        CurrentYaw:= GetYawFromRotation(Current)
        LastYaw:= GetYawFromRotation(Last)
 
        Delta:= CurrentYaw - LastYaw
        if. Delta > 180.0 then Delta - 360.0 else:
            if. Delta < -180.0 then Delta + 360.0 else Delta
 
    GetYawFromRotation(Rot: rotation): float =
        YPR:= Rot.GetYawPitchRollDegrees()
        if. Yaw:= YPR[0] then return Yaw else return 0.0
 
    GetPitchFromRotation(Rot: rotation): float =
        YPR:= Rot.GetYawPitchRollDegrees()
        if. Pitch:= YPR[1] then return Pitch else return 0.0


cursor_manager_device := class(creative_device):
    
    @editable
    Spawners : []player_spawner_device = array{}

    RemoveUIEvent : event(player) = event(player){}

    var CursorInfoPerPlayer : [player]cursor_info = map{}

    OnBegin<override>()<suspends>:void=
        for:
            S : Spawners
        do:
            S.SpawnedEvent.Subscribe(HandleSpawn)

    HandleSpawn(Agent : agent):void=
        if:
            Player := player[Agent]
            not CursorInfoPerPlayer[Player]
            set CursorInfoPerPlayer[Player] = cursor_info{CreativeObj := Self, RemoveUIEvent:=RemoveUIEvent}

    HandleCursorMenu(Player : player, CursorMenu : cursor_menu)<suspends>:void=
        if:
            CursorInfo := CursorInfoPerPlayer[Player]
        then:
            spawn{CursorInfo.HandleCursorMenu(Player,CursorMenu)}