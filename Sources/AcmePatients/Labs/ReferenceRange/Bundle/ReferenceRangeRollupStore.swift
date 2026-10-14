import AcmePlatform
import Foundation

extension Labs {
    /// Keeps reference range rollups by code.
    protocol ReferenceRangeRollupStore {
        func find(_ code: String) -> ReferenceRangeRollup?
        func save(_ item: ReferenceRangeRollup)
        func remove(_ code: String) -> Bool
        func list() -> [ReferenceRangeRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferenceRangeRollupStore: ReferenceRangeRollupStore {
        var items: [String: ReferenceRangeRollup]
        var order: [String]

        init(items: [String: ReferenceRangeRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferenceRangeRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferenceRangeRollup) {
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

        func list() -> [ReferenceRangeRollup] {
            var out: [ReferenceRangeRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferenceRangeRollupStore() -> any ReferenceRangeRollupStore {
        return MemoryReferenceRangeRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferenceRangeRollupStore: ReferenceRangeRollupStore {
        var inner: MemoryReferenceRangeRollupStore
        var cache: TTLCache<ReferenceRangeRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferenceRangeRollupStore, cache: TTLCache<ReferenceRangeRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferenceRangeRollup? {
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

        func save(_ item: ReferenceRangeRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferenceRangeRollup] {
            return inner.list()
        }
    }

    static func newCachedReferenceRangeRollupStore(_ inner: MemoryReferenceRangeRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferenceRangeRollupStore {
        return CachedReferenceRangeRollupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects reference range rollups. Empty fields match all.
    final class ReferenceRangeRollupQuery {
        var unit: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferenceRangeRollup) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferenceRangeRollup]) -> [ReferenceRangeRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferenceRangeRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferenceRangeRollups(_ store: any ReferenceRangeRollupStore, query: ReferenceRangeRollupQuery) -> [ReferenceRangeRollup] {
        return query.apply(store.list())
    }
}
