import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps lenient formulary audits by code.
    protocol LenientFormularyAuditStore {
        func find(_ code: String) -> LenientFormularyAudit?
        func save(_ item: LenientFormularyAudit)
        func remove(_ code: String) -> Bool
        func list() -> [LenientFormularyAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientFormularyAuditStore: LenientFormularyAuditStore {
        var items: [String: LenientFormularyAudit]
        var order: [String]

        init(items: [String: LenientFormularyAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientFormularyAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientFormularyAudit) {
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

        func list() -> [LenientFormularyAudit] {
            var out: [LenientFormularyAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientFormularyAuditStore() -> any LenientFormularyAuditStore {
        return MemoryLenientFormularyAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientFormularyAuditStore: LenientFormularyAuditStore {
        var inner: MemoryLenientFormularyAuditStore
        var cache: TTLCache<LenientFormularyAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientFormularyAuditStore, cache: TTLCache<LenientFormularyAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientFormularyAudit? {
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

        func save(_ item: LenientFormularyAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientFormularyAudit] {
            return inner.list()
        }
    }

    static func newCachedLenientFormularyAuditStore(_ inner: MemoryLenientFormularyAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientFormularyAuditStore {
        return CachedLenientFormularyAuditStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient formulary audits. Empty fields match all.
    final class LenientFormularyAuditQuery {
        var name: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientFormularyAudit) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientFormularyAudit]) -> [LenientFormularyAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientFormularyAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientFormularyAudits(_ store: any LenientFormularyAuditStore, query: LenientFormularyAuditQuery) -> [LenientFormularyAudit] {
        return query.apply(store.list())
    }
}
