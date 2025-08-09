using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }


squid_game_cookie_manager := class(creative_device):
    
    @editable
    LeftClickInput : input_trigger_device = input_trigger_device{}

    @editable
    CompletedTrigger : trigger_device = trigger_device{}

    @editable
    FailedTrigger : trigger_device = trigger_device{}

    @editable
    CursorManager : cursor_manager_device =cursor_manager_device{}

    @editable
    OpenButton : button_device = button_device{}

    OnBegin<override>()<suspends>:void=
        OpenButton.InteractedWithEvent.Subscribe(HandleOpenMenu)

    HandleOpenMenu(Agent : agent):void=
        if:
            Player := player[Agent]
        then:
            CookieGame := squid_game_cookie_menu:
                RemoveUIEvent:=CursorManager.RemoveUIEvent
                CompletedTrigger:=CompletedTrigger
                FailedTrigger:=FailedTrigger
                LeftClickInput:=LeftClickInput
                
            spawn{CursorManager.HandleCursorMenu(Player,CookieGame)}

    OnFailed(MaybeAgent : ?agent):void=
        if:
            Agent := MaybeAgent?
            Player := player[Agent]
        then:
            # remove UI and cancel any waiting loops
            CursorManager.RemoveUIEvent.Signal(Player)
            Print("agent failed I suppose")