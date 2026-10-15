# Validation

Tested on an amd64 Unraid host on 2026-10-15.

- All four XML templates parse. Public URLs, image references, prerequisites and private port layout are checked by validate.py.
- Preparation generates distinct random credentials and canonical my-<container>.xml filenames, rejects invalid input and refuses to overwrite existing credentials.
- A clean PostgreSQL bootstrap creates separate runtime, migrator and web roles. Bootstrap mode is 755 so PostgreSQL can read it; credential files are mode 600 in a private directory.
- The Nocturne API migrations completed. Public HTTPS login/setup pages, direct Dexcom EU synchronization and the WebSocket bridge were verified.
- Historical Nightscout import completed without failed documents. The onboarding completion endpoint was verified separately after account registration.
- Unraid's native registry digest checks report all four images up to date and resolve their icons.
- The full updater ran successfully with a PostgreSQL dump and native DockerMan container recreation. PostgreSQL reported 17.11 afterwards; API and Web remained on matching 0.2.7 versions. Scheduled execution was verified in Unraid's active cron spool.
- Automatic error rollback is implemented but has not been fault-injection tested. Follower/client compatibility and arm64 runtime have not been tested. Initial stack memory use was approximately 1 GiB and is workload-dependent.

The source bundle reviewed was Nocturne v0.2.7. PostgreSQL follows 17-bookworm for patch releases. Gateway uses the upstream 2.3-preview tag. Runtime credentials, personal hostnames, medical data and server backups are excluded from this repository.
