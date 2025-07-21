import { Service, OnStart } from "@flamework/core"

@Service({})
export class Server implements OnStart {
    onStart(): void {
        print("Base Server")
    }
}
