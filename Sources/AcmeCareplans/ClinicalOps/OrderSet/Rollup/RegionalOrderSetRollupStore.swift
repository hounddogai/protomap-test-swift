import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps regional order set rollups by code.
    protocol RegionalOrderSetRollupStore {
        func find(_ code: String) -> RegionalOrderSetRollup?
        func save(_ item: RegionalOrderSetRollup)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalOrderSetRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalOrderSetRollupStore: RegionalOrderSetRollupStore {
        var items: [String: RegionalOrderSetRollup]
        var order: [String]

        init(items: [String: RegionalOrderSetRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalOrderSetRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalOrderSetRollup) {
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

        func list() -> [RegionalOrderSetRollup] {
            var out: [RegionalOrderSetRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalOrderSetRollupStore() -> any RegionalOrderSetRollupStore {
        return MemoryRegionalOrderSetRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalOrderSetRollupStore: RegionalOrderSetRollupStore {
        var inner: MemoryRegionalOrderSetRollupStore
        var cache: TTLCache<RegionalOrderSetRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalOrderSetRollupStore, cache: TTLCache<RegionalOrderSetRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalOrderSetRollup? {
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

        func save(_ item: RegionalOrderSetRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalOrderSetRollup] {
            return inner.list()
        }
    }

    static func newCachedRegionalOrderSetRollupStore(_ inner: MemoryRegionalOrderSetRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalOrderSetRollupStore {
        return CachedRegionalOrderSetRollupStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional order set rollups. Empty fields match all.
    final class RegionalOrderSetRollupQuery {
        var name: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRevision: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalOrderSetRollup) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalOrderSetRollup]) -> [RegionalOrderSetRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalOrderSetRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalOrderSetRollups(_ store: any RegionalOrderSetRollupStore, query: RegionalOrderSetRollupQuery) -> [RegionalOrderSetRollup] {
        return query.apply(store.list())
    }
}
