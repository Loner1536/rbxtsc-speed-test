import { Controller, OnStart } from "@flamework/core"

@Controller({})
export class CommonClient implements OnStart {
    onStart(): void {
        print("Common Client")
    }
}
