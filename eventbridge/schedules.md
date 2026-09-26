# EventBridge Scheduler — 3 staggered daily triggers

`dynamoDb-watermarks` is provisioned at 1 RCU / 1 WCU. Running all three
domains through the state machine's `Map` state concurrently risked
throttling on concurrent `Query`/`PutItem` calls against that table, so
each domain gets its own schedule instead of one schedule firing all
three in parallel — staggered 15 minutes apart.

All three share:
- Timezone: `Asia/Kolkata`
- Target: `ERP-Pipeline` state machine
- Execution role: `Amazon_EventBridge_Scheduler_SFN_2f12106ab8` (see
  `../iam/eventbridge-scheduler-policy.json`)

| Schedule | Time (IST) | Payload |
|---|---|---|
| `erp-pipeline-grn` | 11:00 AM daily | `{"processes": [{"process": "GRN"}]}` |
| `erp-pipeline-pur` | 11:15 AM daily | `{"processes": [{"process": "PUR"}]}` |
| `erp-pipeline-issue` | 11:30 AM daily | `{"processes": [{"process": "ISSUE"}]}` |

Each payload is a single-item array on purpose — the state machine's
`Map` state accepts an array of any length, so this design still
scales back up to a multi-domain batch (or down to a new fourth
domain) without changing `step_functions/state_machine.asl.json`.
