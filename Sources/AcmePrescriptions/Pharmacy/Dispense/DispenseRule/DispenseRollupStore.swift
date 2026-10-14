import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps dispense rollups by code.
    protocol DispenseRollupStore {
        func find(_ code: String) -> DispenseRollup?
        func save(_ item: DispenseRollup)
        func remove(_ code: String) -> Bool
        func list() -> [DispenseRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDispenseRollupStore: DispenseRollupStore {
        var items: [String: DispenseRollup]
        var order: [String]

        init(items: [String: DispenseRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DispenseRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DispenseRollup) {
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

        func list() -> [DispenseRollup] {
            var out: [DispenseRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDispenseRollupStore() -> any DispenseRollupStore {
        return MemoryDispenseRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDispenseRollupStore: DispenseRollupStore {
        var inner: MemoryDispenseRollupStore
        var cache: TTLCache<DispenseRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryDispenseRollupStore, cache: TTLCache<DispenseRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DispenseRollup? {
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

        func save(_ item: DispenseRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DispenseRollup] {
            return inner.list()
        }
    }

    static func newCachedDispenseRollupStore(_ inner: MemoryDispenseRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DispenseRollupStore {
        return CachedDispenseRollupStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects dispense rollups. Empty fields match all.
    final class DispenseRollupQuery {
        var region: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DispenseRollup) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [DispenseRollup]) -> [DispenseRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DispenseRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDispenseRollups(_ store: any DispenseRollupStore, query: DispenseRollupQuery) -> [DispenseRollup] {
        return query.apply(store.list())
    }
}
