import assert from 'node:assert/strict';
import { chmod, mkdir, mkdtemp, readdir, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import test from 'node:test';

const projectRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const runnerPath = join(projectRoot, 'scripts', 'run-device-smoke.mjs');

async function makeExecutable(path, source) {
  await writeFile(path, source, 'utf8');
  await chmod(path, 0o755);
}

async function createFixture({ targets = 'SERIAL-1\n', reportCode = 0 } = {}) {
  const root = await mkdtemp(join(tmpdir(), 'moodlite-device-smoke-'));
  const appHap = join(root, 'moodlite-signed.hap');
  const testHap = join(root, 'moodlite-test-signed.hap');
  const signTool = join(root, 'hap-sign-tool.jar');
  const hdcLog = join(root, 'hdc.log');
  const javaLog = join(root, 'java.log');
  const hdcPath = join(root, 'fake-hdc');
  const javaPath = join(root, 'fake-java');

  await Promise.all([
    writeFile(appHap, 'signed app fixture', 'utf8'),
    writeFile(testHap, 'signed test fixture', 'utf8'),
    writeFile(signTool, 'sign tool fixture', 'utf8'),
  ]);

  await makeExecutable(hdcPath, `#!/bin/sh
printf '%s\\n' "$*" >> ${JSON.stringify(hdcLog)}
if [ "$1" = "list" ] && [ "$2" = "targets" ]; then
  printf '%b' ${JSON.stringify(targets)}
  exit 0
fi
if [ "$3" = "install" ]; then
  printf 'Install successfully.\\n'
  exit 0
fi
if [ "$3" = "shell" ]; then
  printf 'OHOS_REPORT_RESULT: stream=Tests run: 1, Failure: 0, Error: 0, Pass: 1, Ignore: 0\\n'
  printf 'OHOS_REPORT_CODE: ${reportCode}\\n'
  exit 0
fi
printf 'unexpected hdc invocation: %s\\n' "$*" >&2
exit 91
`);

  await makeExecutable(javaPath, `#!/bin/sh
printf '%s\\n' "$*" >> ${JSON.stringify(javaLog)}
exit 0
`);

  return {
    root,
    appHap,
    testHap,
    signTool,
    hdcLog,
    javaLog,
    hdcPath,
    javaPath,
  };
}

function runFixture(fixture, extraArgs = []) {
  return spawnSync(process.execPath, [
    runnerPath,
    '--app-hap', fixture.appHap,
    '--test-hap', fixture.testHap,
    '--hdc', fixture.hdcPath,
    '--java', fixture.javaPath,
    '--sign-tool', fixture.signTool,
    '--flight-mode-confirmed', 'yes',
    ...extraArgs,
  ], {
    cwd: projectRoot,
    encoding: 'utf8',
    env: { ...process.env, TMPDIR: fixture.root },
  });
}

test('rejects an unsigned build artifact before touching the device', async () => {
  const fixture = await createFixture();
  try {
    const unsignedHap = join(fixture.root, 'entry-default-unsigned.hap');
    await writeFile(unsignedHap, 'unsigned fixture', 'utf8');
    fixture.appHap = unsignedHap;

    const result = runFixture(fixture);

    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /unsigned HAP/i);
    await assert.rejects(readFile(fixture.hdcLog, 'utf8'));
  } finally {
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test('fails safely when no HarmonyOS device is connected', async () => {
  const fixture = await createFixture({ targets: '[Empty]\n' });
  try {
    const result = runFixture(fixture);

    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /no connected HarmonyOS device/i);
    const hdcCalls = await readFile(fixture.hdcLog, 'utf8');
    assert.equal(hdcCalls.trim(), 'list targets');
  } finally {
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test('requires a target when more than one device is connected', async () => {
  const fixture = await createFixture({ targets: 'SERIAL-1\nSERIAL-2\n' });
  try {
    const result = runFixture(fixture);

    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /multiple devices/i);
    const hdcCalls = await readFile(fixture.hdcLog, 'utf8');
    assert.equal(hdcCalls.trim(), 'list targets');
  } finally {
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test('does not touch the device without explicit flight-mode confirmation', async () => {
  const fixture = await createFixture();
  try {
    const result = runFixture(fixture, ['--flight-mode-confirmed', 'no']);

    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /flight mode must be confirmed/i);
    await assert.rejects(readFile(fixture.hdcLog, 'utf8'));
  } finally {
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test('finds the sign tool when DEVECO_SDK_HOME points at the SDK root', async () => {
  const fixture = await createFixture();
  try {
    const sdkRoot = join(fixture.root, 'sdk');
    const nestedSignTool = join(
      sdkRoot,
      'default',
      'openharmony',
      'toolchains',
      'lib',
      'hap-sign-tool.jar',
    );
    await mkdir(dirname(nestedSignTool), { recursive: true });
    await writeFile(nestedSignTool, 'nested sign tool fixture', 'utf8');

    const result = spawnSync(process.execPath, [
      runnerPath,
      '--app-hap', fixture.appHap,
      '--test-hap', fixture.testHap,
      '--hdc', fixture.hdcPath,
      '--java', fixture.javaPath,
      '--flight-mode-confirmed', 'yes',
    ], {
      cwd: projectRoot,
      encoding: 'utf8',
      env: {
        ...process.env,
        DEVECO_SDK_HOME: sdkRoot,
        TMPDIR: fixture.root,
      },
    });

    assert.equal(result.status, 0, result.stderr);
    const javaCalls = await readFile(fixture.javaLog, 'utf8');
    assert.match(javaCalls, new RegExp(`-jar ${nestedSignTool.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')} verify-app`));
  } finally {
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test('verifies, installs, and runs the route-safety suite on the selected device', async () => {
  const fixture = await createFixture({ targets: 'SERIAL-1\nSERIAL-2\n' });
  try {
    const result = runFixture(fixture, ['--target', 'SERIAL-2']);

    assert.equal(result.status, 0, result.stderr);
    assert.match(result.stdout, /device smoke test passed/i);

    const javaCalls = (await readFile(fixture.javaLog, 'utf8')).trim().split('\n');
    assert.equal(javaCalls.length, 2);
    assert.match(javaCalls[0], /-jar .*hap-sign-tool\.jar verify-app -inFile .*moodlite-signed\.hap/);
    assert.match(javaCalls[1], /-jar .*hap-sign-tool\.jar verify-app -inFile .*moodlite-test-signed\.hap/);

    const hdcCalls = (await readFile(fixture.hdcLog, 'utf8')).trim().split('\n');
    assert.deepEqual(hdcCalls, [
      'list targets',
      `-t SERIAL-2 install -r ${fixture.appHap} ${fixture.testHap}`,
      '-t SERIAL-2 shell aa test -b com.aycxd.moodlite -m entry_test -s unittest OpenHarmonyTestRunner -s class LaunchRouteSafety',
    ]);
  } finally {
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test('fails when Hypium reports a nonzero result even if hdc exits successfully', async () => {
  const fixture = await createFixture({ reportCode: -1 });
  try {
    const result = runFixture(fixture);

    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /Hypium did not report success/i);
    const leftovers = (await readdir(fixture.root))
      .filter(name => name.startsWith('moodlite-hap-verify-'));
    assert.deepEqual(leftovers, []);
  } finally {
    await rm(fixture.root, { recursive: true, force: true });
  }
});
