import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps closure adjustments by code.
    protocol ClosureAdjustmentStore {
        func find(_ code: String) -> ClosureAdjustment?
        func save(_ item: ClosureAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [ClosureAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClosureAdjustmentStore: ClosureAdjustmentStore {
        var items: [String: ClosureAdjustment]
        var order: [String]

        init(items: [String: ClosureAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClosureAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClosureAdjustment) {
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

        func list() -> [ClosureAdjustment] {
            var out: [ClosureAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClosureAdjustmentStore() -> any ClosureAdjustmentStore {
        return MemoryClosureAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClosureAdjustmentStore: ClosureAdjustmentStore {
        var inner: MemoryClosureAdjustmentStore
        var cache: TTLCache<ClosureAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryClosureAdjustmentStore, cache: TTLCache<ClosureAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClosureAdjustment? {
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

        func save(_ item: ClosureAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClosureAdjustment] {
            return inner.list()
        }
    }

    static func newCachedClosureAdjustmentStore(_ inner: MemoryClosureAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClosureAdjustmentStore {
        return CachedClosureAdjustmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects closure adjustments. Empty fields match all.
    final class ClosureAdjustmentQuery {
        var country: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minWeight: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClosureAdjustment) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ClosureAdjustment]) -> [ClosureAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClosureAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClosureAdjustments(_ store: any ClosureAdjustmentStore, query: ClosureAdjustmentQuery) -> [ClosureAdjustment] {
        return query.apply(store.list())
    }
}
