import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps adaptive priority rollups by code.
    protocol AdaptivePriorityRollupStore {
        func find(_ code: String) -> AdaptivePriorityRollup?
        func save(_ item: AdaptivePriorityRollup)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptivePriorityRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptivePriorityRollupStore: AdaptivePriorityRollupStore {
        var items: [String: AdaptivePriorityRollup]
        var order: [String]

        init(items: [String: AdaptivePriorityRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptivePriorityRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptivePriorityRollup) {
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

        func list() -> [AdaptivePriorityRollup] {
            var out: [AdaptivePriorityRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptivePriorityRollupStore() -> any AdaptivePriorityRollupStore {
        return MemoryAdaptivePriorityRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptivePriorityRollupStore: AdaptivePriorityRollupStore {
        var inner: MemoryAdaptivePriorityRollupStore
        var cache: TTLCache<AdaptivePriorityRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptivePriorityRollupStore, cache: TTLCache<AdaptivePriorityRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptivePriorityRollup? {
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

        func save(_ item: AdaptivePriorityRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptivePriorityRollup] {
            return inner.list()
        }
    }

    static func newCachedAdaptivePriorityRollupStore(_ inner: MemoryAdaptivePriorityRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptivePriorityRollupStore {
        return CachedAdaptivePriorityRollupStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive priority rollups. Empty fields match all.
    final class AdaptivePriorityRollupQuery {
        var segment: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptivePriorityRollup) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptivePriorityRollup]) -> [AdaptivePriorityRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptivePriorityRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptivePriorityRollups(_ store: any AdaptivePriorityRollupStore, query: AdaptivePriorityRollupQuery) -> [AdaptivePriorityRollup] {
        return query.apply(store.list())
    }
}
