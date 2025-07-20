const fs = require("fs")
const path = require("path")

const feature = process.argv[2]
if (!feature) {
    console.error("❌ Usage: node genRojoTree.js <feature>")
    process.exit(1)
}

const toPosix = (p) => p.split(path.sep).join("/")

const outputDir = path.join("sources", feature, "build")

// Helper to get relative paths from outputDir to target folder
function relativeToOutputDir(targetPath) {
    return toPosix(path.relative(outputDir, targetPath))
}

function makeClientEntry(name) {
    return {
        [name]: {
            $className: "Folder",
            client: {
                $path: relativeToOutputDir(path.join("out", name, "client"))
            },
            shared: {
                $path: relativeToOutputDir(path.join("out", name, "shared"))
            }
        }
    }
}

function makeServerEntry(name) {
    return {
        [name]: {
            server: {
                $path: relativeToOutputDir(path.join("out", name, "server"))
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
            rbxts: { $path: relativeToOutputDir("include") },
            $path: relativeToOutputDir("out/include"),
            node_modules: {
                $className: "Folder",
                "@rbxts": {
                    $path: "node_modules/@rbxts"
                },
                "@flamework": {
                    $path: "node_modules/@flamework"
                },
                "@rbxts-js": {
                    $path: "node_modules/@rbxts-js"
                }
            }
        },
        ServerScriptService: {}
    }
}

// Avoid duplicating rbxts
Object.assign(tree.tree.ReplicatedStorage, {
    rbxts: {
        $path: relativeToOutputDir("out/include")
    }
})

Object.assign(tree.tree.ReplicatedStorage, makeClientEntry("base"))
Object.assign(tree.tree.ServerScriptService, makeServerEntry("base"))

if (feature !== "base") {
    Object.assign(tree.tree.ReplicatedStorage, makeClientEntry(feature))
    Object.assign(tree.tree.ServerScriptService, makeServerEntry(feature))
}

fs.mkdirSync(outputDir, { recursive: true })

fs.writeFileSync(
    path.join(outputDir, "default.project.json"),
    JSON.stringify(tree, null, 2)
)
