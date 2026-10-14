import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps claim estimates by code.
    protocol ClaimEstimateStore {
        func find(_ code: String) -> ClaimEstimate?
        func save(_ item: ClaimEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [ClaimEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClaimEstimateStore: ClaimEstimateStore {
        var items: [String: ClaimEstimate]
        var order: [String]

        init(items: [String: ClaimEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClaimEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClaimEstimate) {
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

        func list() -> [ClaimEstimate] {
            var out: [ClaimEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClaimEstimateStore() -> any ClaimEstimateStore {
        return MemoryClaimEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClaimEstimateStore: ClaimEstimateStore {
        var inner: MemoryClaimEstimateStore
        var cache: TTLCache<ClaimEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryClaimEstimateStore, cache: TTLCache<ClaimEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClaimEstimate? {
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

        func save(_ item: ClaimEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClaimEstimate] {
            return inner.list()
        }
    }

    static func newCachedClaimEstimateStore(_ inner: MemoryClaimEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClaimEstimateStore {
        return CachedClaimEstimateStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects claim estimates. Empty fields match all.
    final class ClaimEstimateQuery {
        var unit: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClaimEstimate) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ClaimEstimate]) -> [ClaimEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClaimEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClaimEstimates(_ store: any ClaimEstimateStore, query: ClaimEstimateQuery) -> [ClaimEstimate] {
        return query.apply(store.list())
    }
}
