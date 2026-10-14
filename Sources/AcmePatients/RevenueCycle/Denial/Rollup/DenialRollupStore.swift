import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps denial rollups by code.
    protocol DenialRollupStore {
        func find(_ code: String) -> DenialRollup?
        func save(_ item: DenialRollup)
        func remove(_ code: String) -> Bool
        func list() -> [DenialRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDenialRollupStore: DenialRollupStore {
        var items: [String: DenialRollup]
        var order: [String]

        init(items: [String: DenialRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DenialRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DenialRollup) {
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

        func list() -> [DenialRollup] {
            var out: [DenialRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDenialRollupStore() -> any DenialRollupStore {
        return MemoryDenialRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDenialRollupStore: DenialRollupStore {
        var inner: MemoryDenialRollupStore
        var cache: TTLCache<DenialRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryDenialRollupStore, cache: TTLCache<DenialRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DenialRollup? {
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

        func save(_ item: DenialRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DenialRollup] {
            return inner.list()
        }
    }

    static func newCachedDenialRollupStore(_ inner: MemoryDenialRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DenialRollupStore {
        return CachedDenialRollupStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects denial rollups. Empty fields match all.
    final class DenialRollupQuery {
        var unit: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minMargin: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DenialRollup) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DenialRollup]) -> [DenialRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DenialRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDenialRollups(_ store: any DenialRollupStore, query: DenialRollupQuery) -> [DenialRollup] {
        return query.apply(store.list())
    }
}
