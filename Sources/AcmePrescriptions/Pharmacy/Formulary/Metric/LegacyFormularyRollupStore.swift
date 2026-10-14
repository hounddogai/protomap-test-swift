import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps legacy formulary rollups by code.
    protocol LegacyFormularyRollupStore {
        func find(_ code: String) -> LegacyFormularyRollup?
        func save(_ item: LegacyFormularyRollup)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyFormularyRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyFormularyRollupStore: LegacyFormularyRollupStore {
        var items: [String: LegacyFormularyRollup]
        var order: [String]

        init(items: [String: LegacyFormularyRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyFormularyRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyFormularyRollup) {
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

        func list() -> [LegacyFormularyRollup] {
            var out: [LegacyFormularyRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyFormularyRollupStore() -> any LegacyFormularyRollupStore {
        return MemoryLegacyFormularyRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyFormularyRollupStore: LegacyFormularyRollupStore {
        var inner: MemoryLegacyFormularyRollupStore
        var cache: TTLCache<LegacyFormularyRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyFormularyRollupStore, cache: TTLCache<LegacyFormularyRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyFormularyRollup? {
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

        func save(_ item: LegacyFormularyRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyFormularyRollup] {
            return inner.list()
        }
    }

    static func newCachedLegacyFormularyRollupStore(_ inner: MemoryLegacyFormularyRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyFormularyRollupStore {
        return CachedLegacyFormularyRollupStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy formulary rollups. Empty fields match all.
    final class LegacyFormularyRollupQuery {
        var ward: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyFormularyRollup) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyFormularyRollup]) -> [LegacyFormularyRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyFormularyRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyFormularyRollups(_ store: any LegacyFormularyRollupStore, query: LegacyFormularyRollupQuery) -> [LegacyFormularyRollup] {
        return query.apply(store.list())
    }
}
