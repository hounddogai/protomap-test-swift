import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps strict order set rollups by code.
    protocol StrictOrderSetRollupStore {
        func find(_ code: String) -> StrictOrderSetRollup?
        func save(_ item: StrictOrderSetRollup)
        func remove(_ code: String) -> Bool
        func list() -> [StrictOrderSetRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictOrderSetRollupStore: StrictOrderSetRollupStore {
        var items: [String: StrictOrderSetRollup]
        var order: [String]

        init(items: [String: StrictOrderSetRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictOrderSetRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictOrderSetRollup) {
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

        func list() -> [StrictOrderSetRollup] {
            var out: [StrictOrderSetRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictOrderSetRollupStore() -> any StrictOrderSetRollupStore {
        return MemoryStrictOrderSetRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictOrderSetRollupStore: StrictOrderSetRollupStore {
        var inner: MemoryStrictOrderSetRollupStore
        var cache: TTLCache<StrictOrderSetRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictOrderSetRollupStore, cache: TTLCache<StrictOrderSetRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictOrderSetRollup? {
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

        func save(_ item: StrictOrderSetRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictOrderSetRollup] {
            return inner.list()
        }
    }

    static func newCachedStrictOrderSetRollupStore(_ inner: MemoryStrictOrderSetRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictOrderSetRollupStore {
        return CachedStrictOrderSetRollupStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict order set rollups. Empty fields match all.
    final class StrictOrderSetRollupQuery {
        var locale: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictOrderSetRollup) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictOrderSetRollup]) -> [StrictOrderSetRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictOrderSetRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictOrderSetRollups(_ store: any StrictOrderSetRollupStore, query: StrictOrderSetRollupQuery) -> [StrictOrderSetRollup] {
        return query.apply(store.list())
    }
}
