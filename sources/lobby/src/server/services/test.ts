import { Service, OnStart } from "@flamework/core"

@Service({})
export class LobbyServer implements OnStart {
    onStart(): void {
        print("Lobby Server")
    }
}
