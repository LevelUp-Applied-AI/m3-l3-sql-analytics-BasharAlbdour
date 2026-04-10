## Migration Analysis — Production Scenario

### How I would handle this migration in production

In a production environment with live data, the migration should be done safely and incrementally to avoid downtime or data issues:

- Create the `salary_history` table first without modifying existing tables.
- Backfill data in small batches to avoid overloading the database.
- Use transactions to ensure data integrity and allow rollback in case of failure.
- Add indexes (e.g., on `employee_id`) to improve query performance.
- Gradually update application logic to use the new table while keeping old functionality working.
- Monitor system performance and database load during the migration.
- After validation, fully switch to the new schema.

---

### Risks of adding a new table and backfilling

- **Performance impact:** Large insert operations may slow down the database.
- **Data inconsistency:** Data may change during migration, leading to inaccurate history.
- **Locking issues:** Long queries may block other operations.
- **Duplicate data:** Running the script multiple times may create duplicates.
- **Application mismatch:** Partial migration may cause incorrect results if the app reads incomplete data.
- **Rollback complexity:** Undoing changes can be difficult without proper planning.

---

### Best Practices

- Perform migration during low-traffic periods.
- Use batch processing instead of large single inserts.
- Test the migration in a staging environment first.
- Ensure scripts are idempotent (safe to run multiple times).
- Continuously monitor the system during migration.