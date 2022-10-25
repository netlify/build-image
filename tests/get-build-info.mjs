import { getBuildInfo } from "@netlify/build-info";

const [projectDir] = process.argv.slice(2);
const buildInfo = await getBuildInfo({ projectDir });

if (!buildInfo.jsWorkspaces) {
  // this is needed for jq (basically mimic the logic from buildbot)
  // there jsWorkspaces is just a string slice
  buildInfo.jsWorkspaces = [];
} else {
  buildInfo.jsWorkspaces = buildInfo.jsWorkspaces.packages;
}

console.log(JSON.stringify(buildInfo));
