const fs = require("fs")
const path = require("path")

const feature = process.argv[2]
const includeBase = process.argv[3] !== "false" // default true unless explicitly false

if (!feature) {
    console.error(
        "❌ Usage: node genRojoTree.js <feature> [includeBase=true|false]"
    )
    process.exit(1)
}

const toPosix = (p) => p.split(path.sep).join("/")
const outputDir = path.join("sources", feature, "build")

function relativeToOutputDir(targetPath) {
    return toPosix(path.relative(outputDir, targetPath))
}
function nodeModulesPath(packageName) {
    return relativeToOutputDir(
        path.join(outputDir, "node_modules", packageName)
    )
}

function makeClientEntry(name) {
    return {
        [name]: {
            $className: "Folder",
            client: {
                $path: relativeToOutputDir(
                    path.join("dist/out", name, "client")
                )
            },
            shared: {
                $path: relativeToOutputDir(
                    path.join("dist/out", name, "shared")
                )
            }
        }
    }
}

function makeServerEntry(name) {
    return {
        [name]: {
            server: {
                $path: relativeToOutputDir(
                    path.join("dist/out", name, "server")
                )
            }
        }
    }
}

const tree = {
    name: feature,
    emitLegacyScripts: false,
    tree: {
        $className: "DataModel",
        ReplicatedStorage: {
            rbxts: {
                $path: relativeToOutputDir("dist/include"),
                node_modules: {
                    $className: "Folder",
                    "@rbxts": {
                        $path: nodeModulesPath("@rbxts")
                    },
                    "@flamework": {
                        $path: nodeModulesPath("@flamework")
                    },
                    "@rbxts-js": {
                        $path: nodeModulesPath("@rbxts-js")
                    }
                }
            }
        },
        ServerScriptService: {}
    }
}

if (includeBase) {
    Object.assign(tree.tree.ReplicatedStorage, makeClientEntry("base"))
    Object.assign(tree.tree.ServerScriptService, makeServerEntry("base"))
}

Object.assign(tree.tree.ReplicatedStorage, makeClientEntry(feature))
Object.assign(tree.tree.ServerScriptService, makeServerEntry(feature))

fs.mkdirSync(outputDir, { recursive: true })
fs.writeFileSync(
    path.join(outputDir, "default.project.json"),
    JSON.stringify(tree, null, 2)
)
