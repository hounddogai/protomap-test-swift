import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps float pool quotas by code.
    protocol FloatPoolQuotaStore {
        func find(_ code: String) -> FloatPoolQuota?
        func save(_ item: FloatPoolQuota)
        func remove(_ code: String) -> Bool
        func list() -> [FloatPoolQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFloatPoolQuotaStore: FloatPoolQuotaStore {
        var items: [String: FloatPoolQuota]
        var order: [String]

        init(items: [String: FloatPoolQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FloatPoolQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FloatPoolQuota) {
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

        func list() -> [FloatPoolQuota] {
            var out: [FloatPoolQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFloatPoolQuotaStore() -> any FloatPoolQuotaStore {
        return MemoryFloatPoolQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFloatPoolQuotaStore: FloatPoolQuotaStore {
        var inner: MemoryFloatPoolQuotaStore
        var cache: TTLCache<FloatPoolQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryFloatPoolQuotaStore, cache: TTLCache<FloatPoolQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FloatPoolQuota? {
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

        func save(_ item: FloatPoolQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FloatPoolQuota] {
            return inner.list()
        }
    }

    static func newCachedFloatPoolQuotaStore(_ inner: MemoryFloatPoolQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FloatPoolQuotaStore {
        return CachedFloatPoolQuotaStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects float pool quotas. Empty fields match all.
    final class FloatPoolQuotaQuery {
        var label: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minBudget: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FloatPoolQuota) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FloatPoolQuota]) -> [FloatPoolQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FloatPoolQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFloatPoolQuotas(_ store: any FloatPoolQuotaStore, query: FloatPoolQuotaQuery) -> [FloatPoolQuota] {
        return query.apply(store.list())
    }
}
