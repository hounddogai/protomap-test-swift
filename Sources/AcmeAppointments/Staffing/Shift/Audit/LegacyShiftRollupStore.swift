import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps legacy shift rollups by code.
    protocol LegacyShiftRollupStore {
        func find(_ code: String) -> LegacyShiftRollup?
        func save(_ item: LegacyShiftRollup)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyShiftRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyShiftRollupStore: LegacyShiftRollupStore {
        var items: [String: LegacyShiftRollup]
        var order: [String]

        init(items: [String: LegacyShiftRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyShiftRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyShiftRollup) {
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

        func list() -> [LegacyShiftRollup] {
            var out: [LegacyShiftRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyShiftRollupStore() -> any LegacyShiftRollupStore {
        return MemoryLegacyShiftRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyShiftRollupStore: LegacyShiftRollupStore {
        var inner: MemoryLegacyShiftRollupStore
        var cache: TTLCache<LegacyShiftRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyShiftRollupStore, cache: TTLCache<LegacyShiftRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyShiftRollup? {
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

        func save(_ item: LegacyShiftRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyShiftRollup] {
            return inner.list()
        }
    }

    static func newCachedLegacyShiftRollupStore(_ inner: MemoryLegacyShiftRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyShiftRollupStore {
        return CachedLegacyShiftRollupStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy shift rollups. Empty fields match all.
    final class LegacyShiftRollupQuery {
        var region: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minBudget: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyShiftRollup) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyShiftRollup]) -> [LegacyShiftRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyShiftRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyShiftRollups(_ store: any LegacyShiftRollupStore, query: LegacyShiftRollupQuery) -> [LegacyShiftRollup] {
        return query.apply(store.list())
    }
}
