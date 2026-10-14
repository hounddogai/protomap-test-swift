import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps regional substitution rollups by code.
    protocol RegionalSubstitutionRollupStore {
        func find(_ code: String) -> RegionalSubstitutionRollup?
        func save(_ item: RegionalSubstitutionRollup)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalSubstitutionRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalSubstitutionRollupStore: RegionalSubstitutionRollupStore {
        var items: [String: RegionalSubstitutionRollup]
        var order: [String]

        init(items: [String: RegionalSubstitutionRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalSubstitutionRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalSubstitutionRollup) {
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

        func list() -> [RegionalSubstitutionRollup] {
            var out: [RegionalSubstitutionRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalSubstitutionRollupStore() -> any RegionalSubstitutionRollupStore {
        return MemoryRegionalSubstitutionRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalSubstitutionRollupStore: RegionalSubstitutionRollupStore {
        var inner: MemoryRegionalSubstitutionRollupStore
        var cache: TTLCache<RegionalSubstitutionRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalSubstitutionRollupStore, cache: TTLCache<RegionalSubstitutionRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalSubstitutionRollup? {
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

        func save(_ item: RegionalSubstitutionRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalSubstitutionRollup] {
            return inner.list()
        }
    }

    static func newCachedRegionalSubstitutionRollupStore(_ inner: MemoryRegionalSubstitutionRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalSubstitutionRollupStore {
        return CachedRegionalSubstitutionRollupStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional substitution rollups. Empty fields match all.
    final class RegionalSubstitutionRollupQuery {
        var region: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalSubstitutionRollup) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalSubstitutionRollup]) -> [RegionalSubstitutionRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalSubstitutionRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalSubstitutionRollups(_ store: any RegionalSubstitutionRollupStore, query: RegionalSubstitutionRollupQuery) -> [RegionalSubstitutionRollup] {
        return query.apply(store.list())
    }
}
