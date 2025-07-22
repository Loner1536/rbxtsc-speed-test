import { Service, OnStart } from "@flamework/core"

@Service({})
export class BaseServer implements OnStart {
    onStart(): void {
        print("Base Server")
    }
}
