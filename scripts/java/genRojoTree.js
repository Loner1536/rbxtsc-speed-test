const fs = require("fs");
const path = require("path");

const feature = process.argv[2];
const includeBase = process.argv[3] !== "false"; // default: true

if (!feature) {
    console.error("❌ Usage: node genRojoTree.js <feature> [includeBase=true|false]");
    process.exit(1);
}

const toPosix = (p) => p.split(path.sep).join("/");

// Base directory for relative pathing and output
const sourcesDir = "sources";

function relativeToSources(targetPath) {
    return toPosix(path.relative(sourcesDir, targetPath));
}

function nodeModulesPath(packageName) {
    return relativeToSources(path.join(sourcesDir, "node_modules", packageName));
}

function makeClientEntry(name) {
    return {
        [name]: {
            $className: "Folder",
            client: {
                $path: relativeToSources(path.join("dist/out", name, "client")),
                controllers: {
                    $path: relativeToSources(path.join("dist/out", name, "client", "controllers"))
                }
            },
            shared: {
                $path: relativeToSources(path.join("dist/out", name, "shared"))
            }
        }
    };
}

function makeServerEntry(name) {
    return {
        [name]: {
            server: {
                $path: relativeToSources(path.join("dist/out", name, "server")),
                services: {
                    $path: relativeToSources(path.join("dist/out", name, "server", "services"))
                }
            }
        }
    };
}

// Rojo project structure
const tree = {
    name: feature,
    emitLegacyScripts: false,
    tree: {
        $className: "DataModel",
        ReplicatedStorage: {
            rbxts_include: {
                $path: relativeToSources("dist/include"),
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
};

// Add base if requested
if (includeBase) {
    Object.assign(tree.tree.ReplicatedStorage, makeClientEntry("base"));
    Object.assign(tree.tree.ServerScriptService, makeServerEntry("base"));
}

// Always include the current feature
Object.assign(tree.tree.ReplicatedStorage, makeClientEntry(feature));
Object.assign(tree.tree.ServerScriptService, makeServerEntry(feature));

// Ensure `sources/` exists and write the .project.json
fs.mkdirSync(sourcesDir, { recursive: true });
fs.writeFileSync(
    path.join(sourcesDir, `${feature}.project.json`),
    JSON.stringify(tree, null, 2)
);
