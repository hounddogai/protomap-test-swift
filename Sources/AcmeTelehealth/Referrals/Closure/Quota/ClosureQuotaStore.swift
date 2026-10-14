import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps closure quotas by code.
    protocol ClosureQuotaStore {
        func find(_ code: String) -> ClosureQuota?
        func save(_ item: ClosureQuota)
        func remove(_ code: String) -> Bool
        func list() -> [ClosureQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClosureQuotaStore: ClosureQuotaStore {
        var items: [String: ClosureQuota]
        var order: [String]

        init(items: [String: ClosureQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClosureQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClosureQuota) {
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

        func list() -> [ClosureQuota] {
            var out: [ClosureQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClosureQuotaStore() -> any ClosureQuotaStore {
        return MemoryClosureQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClosureQuotaStore: ClosureQuotaStore {
        var inner: MemoryClosureQuotaStore
        var cache: TTLCache<ClosureQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryClosureQuotaStore, cache: TTLCache<ClosureQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClosureQuota? {
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

        func save(_ item: ClosureQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClosureQuota] {
            return inner.list()
        }
    }

    static func newCachedClosureQuotaStore(_ inner: MemoryClosureQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClosureQuotaStore {
        return CachedClosureQuotaStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects closure quotas. Empty fields match all.
    final class ClosureQuotaQuery {
        var segment: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClosureQuota) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ClosureQuota]) -> [ClosureQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClosureQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClosureQuotas(_ store: any ClosureQuotaStore, query: ClosureQuotaQuery) -> [ClosureQuota] {
        return query.apply(store.list())
    }
}
