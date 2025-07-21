const fs = require("fs");
const path = require("path");

const toPosix = (p) => p.split(path.sep).join("/");

const feature = process.argv[2];
if (!feature) {
    console.error("❌ Usage: node genTsconfig.js <feature>");
    process.exit(1);
}

// Paths
const sourcesDir = "sources";
const featureSrcDir = path.join(sourcesDir, feature, "src");
const tsconfigOutPath = path.join(sourcesDir, `${feature}.tsconfig.json`);
const outDir = path.join("dist/out", feature);

// Relative path helper (from sources/)
const relativeToSources = (targetPath) => path.relative(sourcesDir, targetPath);

const tsconfig = {
    extends: toPosix(relativeToSources("tsconfig.json")),
    compilerOptions: {
        tsBuildInfoFile: toPosix(relativeToSources(`${outDir}.tsbuildinfo`)),
        outDir: toPosix(relativeToSources(outDir)),
        rootDir: toPosix(relativeToSources(featureSrcDir)),
        baseUrl: ".",
        typeRoots: [
            "node_modules/@rbxts",
            "node_modules/@flamework"
        ],
        paths: {
            "@shared/*": [
                toPosix(path.join(relativeToSources(featureSrcDir), "shared", "*"))
            ],
            "@server/*": [
                toPosix(path.join(relativeToSources(featureSrcDir), "server", "*"))
            ],
            "@client/*": [
                toPosix(path.join(relativeToSources(featureSrcDir), "client", "*"))
            ]
        },
        plugins: [
            {
                transform: "rbxts-transformer-flamework",
                obfuscation: true
            }
        ]
    },
    include: [toPosix(relativeToSources(featureSrcDir))],
    exclude: []
};

// Ensure sources/ exists
fs.mkdirSync(sourcesDir, { recursive: true });

// Write to sources/<feature>.tsconfig.json
fs.writeFileSync(tsconfigOutPath, JSON.stringify(tsconfig, null, 2));
