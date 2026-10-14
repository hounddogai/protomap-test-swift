import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps claim adjustments by code.
    protocol ClaimAdjustmentStore {
        func find(_ code: String) -> ClaimAdjustment?
        func save(_ item: ClaimAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [ClaimAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClaimAdjustmentStore: ClaimAdjustmentStore {
        var items: [String: ClaimAdjustment]
        var order: [String]

        init(items: [String: ClaimAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClaimAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClaimAdjustment) {
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

        func list() -> [ClaimAdjustment] {
            var out: [ClaimAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClaimAdjustmentStore() -> any ClaimAdjustmentStore {
        return MemoryClaimAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClaimAdjustmentStore: ClaimAdjustmentStore {
        var inner: MemoryClaimAdjustmentStore
        var cache: TTLCache<ClaimAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryClaimAdjustmentStore, cache: TTLCache<ClaimAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClaimAdjustment? {
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

        func save(_ item: ClaimAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClaimAdjustment] {
            return inner.list()
        }
    }

    static func newCachedClaimAdjustmentStore(_ inner: MemoryClaimAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClaimAdjustmentStore {
        return CachedClaimAdjustmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects claim adjustments. Empty fields match all.
    final class ClaimAdjustmentQuery {
        var country: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minScore: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClaimAdjustment) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [ClaimAdjustment]) -> [ClaimAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClaimAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClaimAdjustments(_ store: any ClaimAdjustmentStore, query: ClaimAdjustmentQuery) -> [ClaimAdjustment] {
        return query.apply(store.list())
    }
}
