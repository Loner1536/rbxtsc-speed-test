const fs = require("fs")
const path = require("path")

const toPosix = (p) => p.split(path.sep).join("/")

const feature = process.argv[2]
if (!feature) {
    console.error("❌ Usage: node genTsconfig.js <feature>")
    process.exit(1)
}

const buildDir = path.join("sources", feature, "build")
const featureDir = path.join("sources", feature)
const srcDir = path.join(featureDir, "src")
const outDir = path.join("out", feature)

// Relative paths from buildDir
const relativeToRoot = path.relative(buildDir, ".")
const relativeToSrc = path.relative(buildDir, srcDir)

const tsBuildInfoFile = path.join(relativeToRoot, outDir + ".tsbuildinfo")
const extendsRelative = path.join(relativeToRoot, "tsconfig.json")
const outDirRelative = path.join(relativeToRoot, outDir)
const includePath = path.relative(buildDir, srcDir)

const tsconfig = {
    extends: toPosix(extendsRelative),
    compilerOptions: {
        tsBuildInfoFile: toPosix(tsBuildInfoFile),
        outDir: toPosix(outDirRelative),
        rootDir: toPosix(relativeToSrc),
        baseUrl: toPosix(relativeToSrc),
        typeRoots: ["node_modules/@rbxts"],
        paths: {
            "@shared/*": [toPosix(path.join(relativeToSrc, "shared", "*"))],
            "@server/*": [toPosix(path.join(relativeToSrc, "server", "*"))],
            "@client/*": [toPosix(path.join(relativeToSrc, "client", "*"))]
        }
    },
    include: [toPosix(includePath)],
    exclude: []
}

fs.mkdirSync(buildDir, { recursive: true })
const outputPath = path.join(buildDir, "tsconfig.json")
fs.writeFileSync(outputPath, JSON.stringify(tsconfig, null, 2))
