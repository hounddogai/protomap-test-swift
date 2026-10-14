import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps weighted interaction exceptions by code.
    protocol WeightedInteractionExceptionStore {
        func find(_ code: String) -> WeightedInteractionException?
        func save(_ item: WeightedInteractionException)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedInteractionException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedInteractionExceptionStore: WeightedInteractionExceptionStore {
        var items: [String: WeightedInteractionException]
        var order: [String]

        init(items: [String: WeightedInteractionException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedInteractionException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedInteractionException) {
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

        func list() -> [WeightedInteractionException] {
            var out: [WeightedInteractionException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedInteractionExceptionStore() -> any WeightedInteractionExceptionStore {
        return MemoryWeightedInteractionExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedInteractionExceptionStore: WeightedInteractionExceptionStore {
        var inner: MemoryWeightedInteractionExceptionStore
        var cache: TTLCache<WeightedInteractionException>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedInteractionExceptionStore, cache: TTLCache<WeightedInteractionException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedInteractionException? {
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

        func save(_ item: WeightedInteractionException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedInteractionException] {
            return inner.list()
        }
    }

    static func newCachedWeightedInteractionExceptionStore(_ inner: MemoryWeightedInteractionExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedInteractionExceptionStore {
        return CachedWeightedInteractionExceptionStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted interaction exceptions. Empty fields match all.
    final class WeightedInteractionExceptionQuery {
        var country: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minRate: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedInteractionException) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedInteractionException]) -> [WeightedInteractionException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedInteractionException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedInteractionExceptions(_ store: any WeightedInteractionExceptionStore, query: WeightedInteractionExceptionQuery) -> [WeightedInteractionException] {
        return query.apply(store.list())
    }
}
