import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps pending recall quotas by code.
    protocol PendingRecallQuotaStore {
        func find(_ code: String) -> PendingRecallQuota?
        func save(_ item: PendingRecallQuota)
        func remove(_ code: String) -> Bool
        func list() -> [PendingRecallQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingRecallQuotaStore: PendingRecallQuotaStore {
        var items: [String: PendingRecallQuota]
        var order: [String]

        init(items: [String: PendingRecallQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingRecallQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingRecallQuota) {
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

        func list() -> [PendingRecallQuota] {
            var out: [PendingRecallQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingRecallQuotaStore() -> any PendingRecallQuotaStore {
        return MemoryPendingRecallQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingRecallQuotaStore: PendingRecallQuotaStore {
        var inner: MemoryPendingRecallQuotaStore
        var cache: TTLCache<PendingRecallQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingRecallQuotaStore, cache: TTLCache<PendingRecallQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingRecallQuota? {
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

        func save(_ item: PendingRecallQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingRecallQuota] {
            return inner.list()
        }
    }

    static func newCachedPendingRecallQuotaStore(_ inner: MemoryPendingRecallQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingRecallQuotaStore {
        return CachedPendingRecallQuotaStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending recall quotas. Empty fields match all.
    final class PendingRecallQuotaQuery {
        var region: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minScore: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingRecallQuota) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingRecallQuota]) -> [PendingRecallQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingRecallQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingRecallQuotas(_ store: any PendingRecallQuotaStore, query: PendingRecallQuotaQuery) -> [PendingRecallQuota] {
        return query.apply(store.list())
    }
}
