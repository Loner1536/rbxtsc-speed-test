import { Controller, OnStart } from "@flamework/core"

@Controller({})
export class Client implements OnStart {
    onStart(): void {
        print("Base Client")
    }
}
