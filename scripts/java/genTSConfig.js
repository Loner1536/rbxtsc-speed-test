const fs = require("fs")
const path = require("path")

const toPosix = (p) => p.split(path.sep).join("/")

const feature = process.argv[2]
if (!feature) {
    console.error("❌ Usage: node genTsconfig.js <feature>")
    process.exit(1)
}

// Base directory is root
const rootDir = "."

// Paths
const sourcesDir = "sources"
const featureSrcDir = path.join(sourcesDir, feature, "src")
const tsconfigOutPath = path.join(rootDir, `${feature}.tsconfig.json`)
const outDir = path.join("dist/out", feature)

// Relative path helper (from root)
const relativeToRoot = (targetPath) =>
    toPosix(path.relative(rootDir, targetPath))

const tsconfig = {
    extends: "./tsconfig.json",
    compilerOptions: {
        tsBuildInfoFile: relativeToRoot(`${outDir}.tsbuildinfo`),
        outDir: relativeToRoot(outDir),
        rootDir: relativeToRoot(featureSrcDir),
        baseUrl: ".",
        typeRoots: ["node_modules/@rbxts", "node_modules/@flamework"],
        paths: {
            "@shared/*": [
                toPosix(path.join(relativeToRoot(featureSrcDir), "shared", "*"))
            ],
            "@server/*": [
                toPosix(path.join(relativeToRoot(featureSrcDir), "server", "*"))
            ],
            "@client/*": [
                toPosix(path.join(relativeToRoot(featureSrcDir), "client", "*"))
            ]
        },
        plugins: [
            {
                transform: "rbxts-transformer-flamework",
                obfuscation: true
            }
        ]
    },
    include: [relativeToRoot(featureSrcDir)],
    exclude: []
}

// Write to root/<feature>.tsconfig.json
fs.writeFileSync(tsconfigOutPath, JSON.stringify(tsconfig, null, 2))
