const fs = require("fs")
const path = require("path")

const feature = process.argv[2]
const includeCommon = process.argv[3] !== "false" // default: true

if (!feature) {
    console.error(
        "❌ Usage: node genRojoTree.js <feature> [includeCommon=true|false]"
    )
    process.exit(1)
}

const toPosix = (p) => p.split(path.sep).join("/")
const rootDir = "."

function relativeToRoot(targetPath) {
    return toPosix(path.relative(rootDir, targetPath))
}

function nodeModulesPath(packageName) {
    return relativeToRoot(path.join("node_modules", packageName))
}

function makeClientEntry(name) {
    return {
        [name]: {
            $className: "Folder",
            client: {
                $path: relativeToRoot(path.join("dist/out", name, "client"))
            },
            shared: {
                $path: relativeToRoot(path.join("dist/out", name, "shared"))
            }
        }
    }
}

function makeServerEntry(name) {
    return {
        [name]: {
            $className: "Folder",
            server: {
                $path: relativeToRoot(path.join("dist/out", name, "server"))
            }
        }
    }
}

// Rojo project structure
const tree = {
    name: feature,
    emitLegacyScripts: false,
    tree: {
        $className: "DataModel",
        ReplicatedStorage: {
            rbxts_include: {
                $path: relativeToRoot("dist/include"),
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

if (includeCommon) {
    Object.assign(tree.tree.ReplicatedStorage, makeClientEntry("common"))
    Object.assign(tree.tree.ServerScriptService, makeServerEntry("common"))
}

Object.assign(tree.tree.ReplicatedStorage, makeClientEntry(feature))
Object.assign(tree.tree.ServerScriptService, makeServerEntry(feature))

// Write project JSON
fs.writeFileSync(
    path.join(rootDir, `${feature}.project.json`),
    JSON.stringify(tree, null, 2)
)
