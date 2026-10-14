import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps rolling modality audits by code.
    protocol RollingModalityAuditStore {
        func find(_ code: String) -> RollingModalityAudit?
        func save(_ item: RollingModalityAudit)
        func remove(_ code: String) -> Bool
        func list() -> [RollingModalityAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingModalityAuditStore: RollingModalityAuditStore {
        var items: [String: RollingModalityAudit]
        var order: [String]

        init(items: [String: RollingModalityAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingModalityAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingModalityAudit) {
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

        func list() -> [RollingModalityAudit] {
            var out: [RollingModalityAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingModalityAuditStore() -> any RollingModalityAuditStore {
        return MemoryRollingModalityAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingModalityAuditStore: RollingModalityAuditStore {
        var inner: MemoryRollingModalityAuditStore
        var cache: TTLCache<RollingModalityAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingModalityAuditStore, cache: TTLCache<RollingModalityAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingModalityAudit? {
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

        func save(_ item: RollingModalityAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingModalityAudit] {
            return inner.list()
        }
    }

    static func newCachedRollingModalityAuditStore(_ inner: MemoryRollingModalityAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingModalityAuditStore {
        return CachedRollingModalityAuditStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling modality audits. Empty fields match all.
    final class RollingModalityAuditQuery {
        var locale: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingModalityAudit) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingModalityAudit]) -> [RollingModalityAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingModalityAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingModalityAudits(_ store: any RollingModalityAuditStore, query: RollingModalityAuditQuery) -> [RollingModalityAudit] {
        return query.apply(store.list())
    }
}
