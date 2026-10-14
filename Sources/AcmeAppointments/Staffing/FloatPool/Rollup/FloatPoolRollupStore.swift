import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps float pool rollups by code.
    protocol FloatPoolRollupStore {
        func find(_ code: String) -> FloatPoolRollup?
        func save(_ item: FloatPoolRollup)
        func remove(_ code: String) -> Bool
        func list() -> [FloatPoolRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFloatPoolRollupStore: FloatPoolRollupStore {
        var items: [String: FloatPoolRollup]
        var order: [String]

        init(items: [String: FloatPoolRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FloatPoolRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FloatPoolRollup) {
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

        func list() -> [FloatPoolRollup] {
            var out: [FloatPoolRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFloatPoolRollupStore() -> any FloatPoolRollupStore {
        return MemoryFloatPoolRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFloatPoolRollupStore: FloatPoolRollupStore {
        var inner: MemoryFloatPoolRollupStore
        var cache: TTLCache<FloatPoolRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryFloatPoolRollupStore, cache: TTLCache<FloatPoolRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FloatPoolRollup? {
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

        func save(_ item: FloatPoolRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FloatPoolRollup] {
            return inner.list()
        }
    }

    static func newCachedFloatPoolRollupStore(_ inner: MemoryFloatPoolRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FloatPoolRollupStore {
        return CachedFloatPoolRollupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects float pool rollups. Empty fields match all.
    final class FloatPoolRollupQuery {
        var label: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FloatPoolRollup) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FloatPoolRollup]) -> [FloatPoolRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FloatPoolRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFloatPoolRollups(_ store: any FloatPoolRollupStore, query: FloatPoolRollupQuery) -> [FloatPoolRollup] {
        return query.apply(store.list())
    }
}
