import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { runInNewContext } from 'node:vm';
import test from 'node:test';

// Exercise the real FormExtensionAbility and view models; only OS services are
// replaced. DevEco's bundled compiler avoids adding a product dependency.
const require = createRequire(import.meta.url);
const studio = process.env.DEVECO_STUDIO_HOME || '/Applications/DevEco-Studio.app/Contents';
const ts = require(resolve(studio, 'tools/hvigor/hvigor/node_modules/typescript'));
const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');

function createFormFixture(rawRecords = '[]') {
  const registered = [];
  const updates = [];
  const services = {
    '@ohos.app.form.FormExtensionAbility': class {
      context = { filesDir: '/test/app/files' };
    },
    '@ohos.app.form.formInfo': {
      FormParam: { IDENTITY_KEY: 'ohos.extra.param.key.form_identity' },
    },
    '@ohos.app.form.formBindingData': { createFormBindingData: (data) => ({ data }) },
    '@ohos.app.form.formProvider': {
      updateForm: async (id, binding) => { updates.push({ id, data: binding.data }); },
    },
    '@ohos.data.preferences': {
      getPreferences: async (_context, store) => {
        assert.equal(store, 'moodlite_db');
        return { get: async (key) => { assert.equal(key, 'records'); return rawRecords; } };
      },
    },
  };
  const cache = new Map();
  function load(path) {
    if (cache.has(path)) return cache.get(path).exports;
    const module = { exports: {} };
    cache.set(path, module);
    const compiled = ts.transpileModule(readFileSync(path, 'utf8'), {
      compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020 },
    }).outputText;
    runInNewContext(compiled, {
      module,
      exports: module.exports,
      console,
      AppStorage: { get: () => false },
      require: (specifier) => {
        if (specifier in services) return { default: services[specifier] };
        if (specifier.endsWith('/WidgetSyncManager')) {
          return { default: { addFormId: async (_context, id) => { registered.push(id); } } };
        }
        if (!specifier.startsWith('.')) throw new Error(`Unexpected dependency: ${specifier}`);
        return load(resolve(dirname(path), specifier + '.ets'));
      },
    }, { filename: path });
    return module.exports;
  }
  const { default: EntryFormAbility } = load(resolve(root, 'entry/src/main/ets/entryformability/EntryFormAbility.ets'));
  return { ability: new EntryFormAbility(), registered, updates };
}

test('adding a system-provided card registers its ID for later record updates', () => {
  const fixture = createFormFixture();
  fixture.ability.onAddForm({ parameters: { 'ohos.extra.param.key.form_identity': '577973689' } });
  assert.deepEqual(fixture.registered, ['577973689']);
});

test('adding a card publishes its initial local summary to the same system ID', async () => {
  const now = new Date();
  const dateStr = [now.getFullYear(), String(now.getMonth() + 1).padStart(2, '0'), String(now.getDate()).padStart(2, '0')].join('-');
  const fixture = createFormFixture(JSON.stringify([{
    id: 'today-record', timestamp: now.getTime(), dateStr, score: 2,
    text: 'local only', images: [], location: '', tags: ['休息'],
  }]));
  fixture.ability.onAddForm({ parameters: { 'ohos.extra.param.key.form_identity': '577973689' } });
  await new Promise(setImmediate);
  assert.equal(fixture.updates.length, 1);
  assert.equal(fixture.updates[0].id, '577973689');
  assert.equal(fixture.updates[0].data.moodLabel, '愉悦');
  assert.equal(fixture.updates[0].data.todayScore, 2);
  assert.equal(fixture.updates[0].data.recordDays, 1);
});
