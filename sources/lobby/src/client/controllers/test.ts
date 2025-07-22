import { Controller, OnStart } from "@flamework/core"

@Controller({})
export class LobbyClient implements OnStart {
    onStart(): void {
        print("Lobby Client")
    }
}
