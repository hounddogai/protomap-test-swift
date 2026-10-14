import Foundation
import GRDB
import GRPCCore

/// A persistence model, independent of the transport representation.
public struct StoredRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    public static let databaseTableName = "records"
    public let tenant: String
    public let kind: String
    public let recordID: String
    public let body: Data

    public init(tenant: String, kind: String, recordID: String, body: Data) {
        self.tenant = tenant
        self.kind = kind
        self.recordID = recordID
        self.body = body
    }
}

public protocol RecordRepository: Sendable {
    func save(_ record: StoredRecord) async throws
    func recordAction(tenant: String, kind: String, action: String, detail: String) async throws
    func count(tenant: String) async throws -> Int
}

/// GRDB serializes writes and commits each record or audit entry in a transaction.
public final class SQLiteRepository: RecordRepository {
    private let database: DatabaseQueue

    public init(path: String) throws {
        database = try DatabaseQueue(path: path)
        var migrations = DatabaseMigrator()
        migrations.registerMigration("001_records") { db in
            try db.create(table: "records") { table in
                table.column("tenant", .text).notNull()
                table.column("kind", .text).notNull()
                table.column("recordID", .text).notNull()
                table.column("body", .blob).notNull()
                table.primaryKey(["tenant", "kind", "recordID"])
            }
            try db.create(table: "actions") { table in
                table.autoIncrementedPrimaryKey("id")
                table.column("tenant", .text).notNull()
                table.column("kind", .text).notNull()
                table.column("action", .text).notNull()
                table.column("detail", .text).notNull()
            }
        }
        try migrations.migrate(database)
    }

    public func save(_ record: StoredRecord) async throws {
        do {
            try await database.write { db in try record.save(db) }
        } catch {
            throw RPCError(code: .internalError, message: "Unable to persist record", cause: error)
        }
    }

    public func recordAction(tenant: String, kind: String, action: String, detail: String) async throws {
        do {
            try await database.write { db in
                try db.execute(
                    sql: "INSERT INTO actions (tenant, kind, action, detail) VALUES (?, ?, ?, ?)",
                    arguments: [tenant, kind, action, detail]
                )
            }
        } catch {
            throw RPCError(code: .internalError, message: "Unable to record action", cause: error)
        }
    }

    public func count(tenant: String) async throws -> Int {
        try await database.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM records WHERE tenant = ?", arguments: [tenant]) ?? 0
        }
    }
}
