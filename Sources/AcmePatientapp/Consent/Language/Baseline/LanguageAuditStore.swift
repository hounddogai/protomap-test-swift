import AcmePlatform
import Foundation

extension Consent {
    /// Keeps language audits by code.
    protocol LanguageAuditStore {
        func find(_ code: String) -> LanguageAudit?
        func save(_ item: LanguageAudit)
        func remove(_ code: String) -> Bool
        func list() -> [LanguageAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLanguageAuditStore: LanguageAuditStore {
        var items: [String: LanguageAudit]
        var order: [String]

        init(items: [String: LanguageAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LanguageAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LanguageAudit) {
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

        func list() -> [LanguageAudit] {
            var out: [LanguageAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLanguageAuditStore() -> any LanguageAuditStore {
        return MemoryLanguageAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLanguageAuditStore: LanguageAuditStore {
        var inner: MemoryLanguageAuditStore
        var cache: TTLCache<LanguageAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryLanguageAuditStore, cache: TTLCache<LanguageAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LanguageAudit? {
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

        func save(_ item: LanguageAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LanguageAudit] {
            return inner.list()
        }
    }

    static func newCachedLanguageAuditStore(_ inner: MemoryLanguageAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LanguageAuditStore {
        return CachedLanguageAuditStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects language audits. Empty fields match all.
    final class LanguageAuditQuery {
        var unit: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LanguageAudit) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LanguageAudit]) -> [LanguageAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LanguageAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLanguageAudits(_ store: any LanguageAuditStore, query: LanguageAuditQuery) -> [LanguageAudit] {
        return query.apply(store.list())
    }
}
