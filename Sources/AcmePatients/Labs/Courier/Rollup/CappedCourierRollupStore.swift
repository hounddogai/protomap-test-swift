import AcmePlatform
import Foundation

extension Labs {
    /// Keeps capped courier rollups by code.
    protocol CappedCourierRollupStore {
        func find(_ code: String) -> CappedCourierRollup?
        func save(_ item: CappedCourierRollup)
        func remove(_ code: String) -> Bool
        func list() -> [CappedCourierRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedCourierRollupStore: CappedCourierRollupStore {
        var items: [String: CappedCourierRollup]
        var order: [String]

        init(items: [String: CappedCourierRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedCourierRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedCourierRollup) {
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

        func list() -> [CappedCourierRollup] {
            var out: [CappedCourierRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedCourierRollupStore() -> any CappedCourierRollupStore {
        return MemoryCappedCourierRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedCourierRollupStore: CappedCourierRollupStore {
        var inner: MemoryCappedCourierRollupStore
        var cache: TTLCache<CappedCourierRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedCourierRollupStore, cache: TTLCache<CappedCourierRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedCourierRollup? {
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

        func save(_ item: CappedCourierRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedCourierRollup] {
            return inner.list()
        }
    }

    static func newCachedCappedCourierRollupStore(_ inner: MemoryCappedCourierRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedCourierRollupStore {
        return CachedCappedCourierRollupStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped courier rollups. Empty fields match all.
    final class CappedCourierRollupQuery {
        var name: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedCourierRollup) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedCourierRollup]) -> [CappedCourierRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedCourierRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedCourierRollups(_ store: any CappedCourierRollupStore, query: CappedCourierRollupQuery) -> [CappedCourierRollup] {
        return query.apply(store.list())
    }
}
