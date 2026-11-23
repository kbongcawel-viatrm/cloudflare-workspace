import { access } from "node:fs/promises";

await access(new URL("../src/index.ts", import.meta.url));
console.log("Build preflight passed.");
