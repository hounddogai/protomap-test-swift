import AcmePlatform
import Foundation

extension Labs {
    /// Keeps capped panel audits by code.
    protocol CappedPanelAuditStore {
        func find(_ code: String) -> CappedPanelAudit?
        func save(_ item: CappedPanelAudit)
        func remove(_ code: String) -> Bool
        func list() -> [CappedPanelAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedPanelAuditStore: CappedPanelAuditStore {
        var items: [String: CappedPanelAudit]
        var order: [String]

        init(items: [String: CappedPanelAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedPanelAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedPanelAudit) {
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

        func list() -> [CappedPanelAudit] {
            var out: [CappedPanelAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedPanelAuditStore() -> any CappedPanelAuditStore {
        return MemoryCappedPanelAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedPanelAuditStore: CappedPanelAuditStore {
        var inner: MemoryCappedPanelAuditStore
        var cache: TTLCache<CappedPanelAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedPanelAuditStore, cache: TTLCache<CappedPanelAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedPanelAudit? {
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

        func save(_ item: CappedPanelAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedPanelAudit] {
            return inner.list()
        }
    }

    static func newCachedCappedPanelAuditStore(_ inner: MemoryCappedPanelAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedPanelAuditStore {
        return CachedCappedPanelAuditStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped panel audits. Empty fields match all.
    final class CappedPanelAuditQuery {
        var name: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedPanelAudit) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedPanelAudit]) -> [CappedPanelAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedPanelAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedPanelAudits(_ store: any CappedPanelAuditStore, query: CappedPanelAuditQuery) -> [CappedPanelAudit] {
        return query.apply(store.list())
    }
}
