import AcmePlatform
import Foundation

extension Labs {
    /// Keeps strict reference range rollups by code.
    protocol StrictReferenceRangeRollupStore {
        func find(_ code: String) -> StrictReferenceRangeRollup?
        func save(_ item: StrictReferenceRangeRollup)
        func remove(_ code: String) -> Bool
        func list() -> [StrictReferenceRangeRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictReferenceRangeRollupStore: StrictReferenceRangeRollupStore {
        var items: [String: StrictReferenceRangeRollup]
        var order: [String]

        init(items: [String: StrictReferenceRangeRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictReferenceRangeRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictReferenceRangeRollup) {
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

        func list() -> [StrictReferenceRangeRollup] {
            var out: [StrictReferenceRangeRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictReferenceRangeRollupStore() -> any StrictReferenceRangeRollupStore {
        return MemoryStrictReferenceRangeRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictReferenceRangeRollupStore: StrictReferenceRangeRollupStore {
        var inner: MemoryStrictReferenceRangeRollupStore
        var cache: TTLCache<StrictReferenceRangeRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictReferenceRangeRollupStore, cache: TTLCache<StrictReferenceRangeRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictReferenceRangeRollup? {
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

        func save(_ item: StrictReferenceRangeRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictReferenceRangeRollup] {
            return inner.list()
        }
    }

    static func newCachedStrictReferenceRangeRollupStore(_ inner: MemoryStrictReferenceRangeRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictReferenceRangeRollupStore {
        return CachedStrictReferenceRangeRollupStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict reference range rollups. Empty fields match all.
    final class StrictReferenceRangeRollupQuery {
        var unit: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minBudget: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictReferenceRangeRollup) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [StrictReferenceRangeRollup]) -> [StrictReferenceRangeRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictReferenceRangeRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictReferenceRangeRollups(_ store: any StrictReferenceRangeRollupStore, query: StrictReferenceRangeRollupQuery) -> [StrictReferenceRangeRollup] {
        return query.apply(store.list())
    }
}
