import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps pending claim estimates by code.
    protocol PendingClaimEstimateStore {
        func find(_ code: String) -> PendingClaimEstimate?
        func save(_ item: PendingClaimEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [PendingClaimEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingClaimEstimateStore: PendingClaimEstimateStore {
        var items: [String: PendingClaimEstimate]
        var order: [String]

        init(items: [String: PendingClaimEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingClaimEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingClaimEstimate) {
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

        func list() -> [PendingClaimEstimate] {
            var out: [PendingClaimEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingClaimEstimateStore() -> any PendingClaimEstimateStore {
        return MemoryPendingClaimEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingClaimEstimateStore: PendingClaimEstimateStore {
        var inner: MemoryPendingClaimEstimateStore
        var cache: TTLCache<PendingClaimEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingClaimEstimateStore, cache: TTLCache<PendingClaimEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingClaimEstimate? {
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

        func save(_ item: PendingClaimEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingClaimEstimate] {
            return inner.list()
        }
    }

    static func newCachedPendingClaimEstimateStore(_ inner: MemoryPendingClaimEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingClaimEstimateStore {
        return CachedPendingClaimEstimateStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending claim estimates. Empty fields match all.
    final class PendingClaimEstimateQuery {
        var ward: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minRetries: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingClaimEstimate) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingClaimEstimate]) -> [PendingClaimEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingClaimEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingClaimEstimates(_ store: any PendingClaimEstimateStore, query: PendingClaimEstimateQuery) -> [PendingClaimEstimate] {
        return query.apply(store.list())
    }
}
