import { Service, OnStart } from "@flamework/core"

@Service({})
export class CommonServer implements OnStart {
    onStart(): void {
        print("Common Server")
    }
}
