import { Service, OnStart } from "@rbxts/flamework"

@Service({})
export class Server implements OnStart {
    onStart(): void {
        print("Base Server")
    }
}
