import { Controller, OnStart } from "@flamework/core"

@Controller({})
export class BaseClient implements OnStart {
    onStart(): void {
        print("Base Client")
    }
}
