# Records with SwiftData

Moderate (`~/gh/moderate`, `Moderate/Models/` and `Logic/DataStore.swift`) is the reference, including
optional iCloud sync and backups.

1. **Model**: `@Model final class Thing` in `Sprout/Models/`. Give **every property a default
   value or make it optional**, and no unique constraints: CloudKit sync requires both, and adding sync
   later is far easier if the model already complies. Relationships must be optional.
2. **Container**: create one `ModelContainer` in `SproutApp` and attach it with
   `.modelContainer(container)`. For tests, an in-memory configuration
   (`ModelConfiguration(isStoredInMemoryOnly: true)`).
3. **Reading**: `@Query` in views (with a `SortDescriptor` and, for big lists, a predicate and fetch
   limit); logic that the widgets or intents need goes in a plain function that takes a `ModelContext`.
4. **Widgets can't open the store** (keep them off it): after writing, compute what they show and save
   a `WidgetSnapshot` (see widget.md).
5. **Changing a model after release**: only add properties, each optional or with a default.
   Renaming or removing breaks existing stores (and the CloudKit production schema can never lose a
   field). Use a `VersionedSchema` + `SchemaMigrationPlan` for anything more.
6. **iCloud sync** (often a Pro feature): needs the iCloud + CloudKit capability, a container
   `iCloud.<bundle id>`, the Push Notifications capability and `remote-notification` background mode,
   and deploying the schema to production before release. Follow Moderate's `project-icloud.yml` and
   its RELEASING.md "CloudKit schema" section, and update the privacy policy ("stored in your own
   iCloud").
7. **Backup/export**: if users would be sad to lose the data, add export (Codable JSON via the share
   sheet, CSV for spreadsheets) like Moderate's `Backup.swift`.
8. **Privacy**: data stays on device, so "Data Not Collected" still holds; say where it's stored in
   `PRIVACY.md` and `docs/privacy/index.html`.
