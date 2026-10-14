import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps seasonal substitution variances by code.
    protocol SeasonalSubstitutionVarianceStore {
        func find(_ code: String) -> SeasonalSubstitutionVariance?
        func save(_ item: SeasonalSubstitutionVariance)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalSubstitutionVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalSubstitutionVarianceStore: SeasonalSubstitutionVarianceStore {
        var items: [String: SeasonalSubstitutionVariance]
        var order: [String]

        init(items: [String: SeasonalSubstitutionVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalSubstitutionVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalSubstitutionVariance) {
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

        func list() -> [SeasonalSubstitutionVariance] {
            var out: [SeasonalSubstitutionVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalSubstitutionVarianceStore() -> any SeasonalSubstitutionVarianceStore {
        return MemorySeasonalSubstitutionVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalSubstitutionVarianceStore: SeasonalSubstitutionVarianceStore {
        var inner: MemorySeasonalSubstitutionVarianceStore
        var cache: TTLCache<SeasonalSubstitutionVariance>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalSubstitutionVarianceStore, cache: TTLCache<SeasonalSubstitutionVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalSubstitutionVariance? {
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

        func save(_ item: SeasonalSubstitutionVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalSubstitutionVariance] {
            return inner.list()
        }
    }

    static func newCachedSeasonalSubstitutionVarianceStore(_ inner: MemorySeasonalSubstitutionVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalSubstitutionVarianceStore {
        return CachedSeasonalSubstitutionVarianceStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal substitution variances. Empty fields match all.
    final class SeasonalSubstitutionVarianceQuery {
        var name: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minCost: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalSubstitutionVariance) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [SeasonalSubstitutionVariance]) -> [SeasonalSubstitutionVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalSubstitutionVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalSubstitutionVariances(_ store: any SeasonalSubstitutionVarianceStore, query: SeasonalSubstitutionVarianceQuery) -> [SeasonalSubstitutionVariance] {
        return query.apply(store.list())
    }
}
