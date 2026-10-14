import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps weighted substitution rollups by code.
    protocol WeightedSubstitutionRollupStore {
        func find(_ code: String) -> WeightedSubstitutionRollup?
        func save(_ item: WeightedSubstitutionRollup)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedSubstitutionRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedSubstitutionRollupStore: WeightedSubstitutionRollupStore {
        var items: [String: WeightedSubstitutionRollup]
        var order: [String]

        init(items: [String: WeightedSubstitutionRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedSubstitutionRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedSubstitutionRollup) {
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

        func list() -> [WeightedSubstitutionRollup] {
            var out: [WeightedSubstitutionRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedSubstitutionRollupStore() -> any WeightedSubstitutionRollupStore {
        return MemoryWeightedSubstitutionRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedSubstitutionRollupStore: WeightedSubstitutionRollupStore {
        var inner: MemoryWeightedSubstitutionRollupStore
        var cache: TTLCache<WeightedSubstitutionRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedSubstitutionRollupStore, cache: TTLCache<WeightedSubstitutionRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedSubstitutionRollup? {
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

        func save(_ item: WeightedSubstitutionRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedSubstitutionRollup] {
            return inner.list()
        }
    }

    static func newCachedWeightedSubstitutionRollupStore(_ inner: MemoryWeightedSubstitutionRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedSubstitutionRollupStore {
        return CachedWeightedSubstitutionRollupStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted substitution rollups. Empty fields match all.
    final class WeightedSubstitutionRollupQuery {
        var country: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minCopay: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedSubstitutionRollup) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedSubstitutionRollup]) -> [WeightedSubstitutionRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedSubstitutionRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedSubstitutionRollups(_ store: any WeightedSubstitutionRollupStore, query: WeightedSubstitutionRollupQuery) -> [WeightedSubstitutionRollup] {
        return query.apply(store.list())
    }
}
