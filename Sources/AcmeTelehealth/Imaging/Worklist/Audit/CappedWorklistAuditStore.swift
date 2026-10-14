import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps capped worklist audits by code.
    protocol CappedWorklistAuditStore {
        func find(_ code: String) -> CappedWorklistAudit?
        func save(_ item: CappedWorklistAudit)
        func remove(_ code: String) -> Bool
        func list() -> [CappedWorklistAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedWorklistAuditStore: CappedWorklistAuditStore {
        var items: [String: CappedWorklistAudit]
        var order: [String]

        init(items: [String: CappedWorklistAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedWorklistAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedWorklistAudit) {
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

        func list() -> [CappedWorklistAudit] {
            var out: [CappedWorklistAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedWorklistAuditStore() -> any CappedWorklistAuditStore {
        return MemoryCappedWorklistAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedWorklistAuditStore: CappedWorklistAuditStore {
        var inner: MemoryCappedWorklistAuditStore
        var cache: TTLCache<CappedWorklistAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedWorklistAuditStore, cache: TTLCache<CappedWorklistAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedWorklistAudit? {
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

        func save(_ item: CappedWorklistAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedWorklistAudit] {
            return inner.list()
        }
    }

    static func newCachedCappedWorklistAuditStore(_ inner: MemoryCappedWorklistAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedWorklistAuditStore {
        return CachedCappedWorklistAuditStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped worklist audits. Empty fields match all.
    final class CappedWorklistAuditQuery {
        var label: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMargin: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedWorklistAudit) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedWorklistAudit]) -> [CappedWorklistAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedWorklistAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedWorklistAudits(_ store: any CappedWorklistAuditStore, query: CappedWorklistAuditQuery) -> [CappedWorklistAudit] {
        return query.apply(store.list())
    }
}
