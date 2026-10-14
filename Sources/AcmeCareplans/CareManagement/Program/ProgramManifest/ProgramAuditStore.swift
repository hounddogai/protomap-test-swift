import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps program audits by code.
    protocol ProgramAuditStore {
        func find(_ code: String) -> ProgramAudit?
        func save(_ item: ProgramAudit)
        func remove(_ code: String) -> Bool
        func list() -> [ProgramAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProgramAuditStore: ProgramAuditStore {
        var items: [String: ProgramAudit]
        var order: [String]

        init(items: [String: ProgramAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProgramAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProgramAudit) {
            if !(items[item.code] != nil) {
                order.append(item.code)
            }
            items[item.code] = item
        }

        func remove(_ code: String) -> Bool {
            if !(items[code] != nil) {
                return false
            }
            items.removeValue(forKey: code)
            var kept: [String] = []
            for existing in order {
                if existing != code {
                    kept.append(existing)
                }
            }
            order = kept
            return true
        }

        func list() -> [ProgramAudit] {
            var out: [ProgramAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProgramAuditStore() -> any ProgramAuditStore {
        return MemoryProgramAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProgramAuditStore: ProgramAuditStore {
        var inner: MemoryProgramAuditStore
        var cache: TTLCache<ProgramAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryProgramAuditStore, cache: TTLCache<ProgramAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProgramAudit? {
            guard let hit = cache.getValue(code) else {
                misses += 1
                guard let found = inner.find(code) else {
                    return nil
                }
                cache.put(code, value: found)
                return found
            }
            hits += 1
            return hit
        }

        func save(_ item: ProgramAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProgramAudit] {
            return inner.list()
        }
    }

    static func newCachedProgramAuditStore(_ inner: MemoryProgramAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProgramAuditStore {
        return CachedProgramAuditStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects program audits. Empty fields match all.
    final class ProgramAuditQuery {
        var category: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minAmount: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProgramAudit) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ProgramAudit]) -> [ProgramAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProgramAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProgramAudits(_ store: any ProgramAuditStore, query: ProgramAuditQuery) -> [ProgramAudit] {
        return query.apply(store.list())
    }
}
