// Deterministic local seed for the Firestore EMULATOR via its REST API.
// Talks ONLY to localhost:8080 with the demo project. No production access.
const HOST = 'http://localhost:8080';
const PROJECT = 'demo-sangaso-local';

const svc = (id) =>
  `v1/projects/${PROJECT}/databases/(default)/documents/services/${id}`;

const user = (id) =>
  `v1/projects/${PROJECT}/databases/(default)/documents/users/${id}`;

const ts = (iso) => ({ stringValue: iso });

const services = [
  {
    providerId: { stringValue: 'prov-001' },
    name: { stringValue: 'Deep apartment clean' },
    description: { stringValue: 'Full apartment clean with supplies' },
    category: { stringValue: 'Cleaning' },
    price: { doubleValue: 250 },
    imageUrls: { arrayValue: { values: [] } },
    isActive: { booleanValue: true },
    createdAt: ts('2026-01-01T00:00:00Z'),
    updatedAt: ts('2026-01-01T00:00:00Z'),
  },
  {
    providerId: { stringValue: 'prov-002' },
    name: { stringValue: 'Bathroom plumbing repair' },
    description: { stringValue: 'Leaking taps and pipes' },
    category: { stringValue: 'Plumbing' },
    price: { doubleValue: 180 },
    imageUrls: { arrayValue: { values: [] } },
    isActive: { booleanValue: true },
    createdAt: ts('2026-01-01T00:00:00Z'),
    updatedAt: ts('2026-01-01T00:00:00Z'),
  },
  {
    providerId: { stringValue: 'prov-003' },
    name: { stringValue: 'Ceiling fan installation' },
    description: { stringValue: 'Ceiling fan install small job' },
    category: { stringValue: 'Electrical' },
    price: { doubleValue: 150 },
    imageUrls: { arrayValue: { values: [] } },
    isActive: { booleanValue: true },
    createdAt: ts('2026-01-01T00:00:00Z'),
    updatedAt: ts('2026-01-01T00:00:00Z'),
  },
];

const users = [
  {
    id: { stringValue: 'seeker-001' },
    email: { stringValue: 'seeker@demo-sangaso-local.test' },
    role: { stringValue: 'seeker' },
    isVerified: { booleanValue: true },
    displayName: { stringValue: 'Demo Seeker' },
    createdAt: ts('2026-01-01T00:00:00Z'),
    updatedAt: ts('2026-01-01T00:00:00Z'),
  },
  {
    id: { stringValue: 'provider-001' },
    email: { stringValue: 'provider@demo-sangaso-local.test' },
    role: { stringValue: 'provider' },
    isVerified: { booleanValue: true },
    displayName: { stringValue: 'Demo Provider' },
    category: { stringValue: 'Cleaning' },
    basePrice: { doubleValue: 250 },
    createdAt: ts('2026-01-01T00:00:00Z'),
    updatedAt: ts('2026-01-01T00:00:00Z'),
  },
];

async function put(url, fields) {
  const res = await fetch(`${HOST}/${url}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields }),
  });
  if (!res.ok) throw new Error(`${url}: ${res.status} ${await res.text()}`);
  return res.json();
}

async function main() {
  let i = 0;
  for (const fields of services) {
    const id = ['svc-clean-001', 'svc-plumb-001', 'svc-elec-001'][i++];
    const doc = await put(svc(id), fields);
    console.log('seeded', doc.name);
  }
  await put(user('seeker-001'), users[0]);
  await put(user('provider-001'), users[1]);

  const check = await fetch(
    `${HOST}/v1/projects/${PROJECT}/databases/(default)/documents/services?pageSize=5`
  ).then((r) => r.json());
  console.log(`Firestore EMULATOR now holds ${check.documents?.length ?? 0} service docs`);
  if ((check.documents?.length ?? 0) !== 3) throw new Error('seed verification failed');
}

main().catch((err) => {
  console.error('Seed failed:', err.message);
  process.exit(1);
});
