import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps float pool audits by code.
    protocol FloatPoolAuditStore {
        func find(_ code: String) -> FloatPoolAudit?
        func save(_ item: FloatPoolAudit)
        func remove(_ code: String) -> Bool
        func list() -> [FloatPoolAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFloatPoolAuditStore: FloatPoolAuditStore {
        var items: [String: FloatPoolAudit]
        var order: [String]

        init(items: [String: FloatPoolAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FloatPoolAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FloatPoolAudit) {
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

        func list() -> [FloatPoolAudit] {
            var out: [FloatPoolAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFloatPoolAuditStore() -> any FloatPoolAuditStore {
        return MemoryFloatPoolAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFloatPoolAuditStore: FloatPoolAuditStore {
        var inner: MemoryFloatPoolAuditStore
        var cache: TTLCache<FloatPoolAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryFloatPoolAuditStore, cache: TTLCache<FloatPoolAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FloatPoolAudit? {
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

        func save(_ item: FloatPoolAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FloatPoolAudit] {
            return inner.list()
        }
    }

    static func newCachedFloatPoolAuditStore(_ inner: MemoryFloatPoolAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FloatPoolAuditStore {
        return CachedFloatPoolAuditStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects float pool audits. Empty fields match all.
    final class FloatPoolAuditQuery {
        var unit: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minCost: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FloatPoolAudit) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FloatPoolAudit]) -> [FloatPoolAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FloatPoolAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFloatPoolAudits(_ store: any FloatPoolAuditStore, query: FloatPoolAuditQuery) -> [FloatPoolAudit] {
        return query.apply(store.list())
    }
}
