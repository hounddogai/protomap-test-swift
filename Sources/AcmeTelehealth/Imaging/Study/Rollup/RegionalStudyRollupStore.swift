import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps regional study rollups by code.
    protocol RegionalStudyRollupStore {
        func find(_ code: String) -> RegionalStudyRollup?
        func save(_ item: RegionalStudyRollup)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalStudyRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalStudyRollupStore: RegionalStudyRollupStore {
        var items: [String: RegionalStudyRollup]
        var order: [String]

        init(items: [String: RegionalStudyRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalStudyRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalStudyRollup) {
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

        func list() -> [RegionalStudyRollup] {
            var out: [RegionalStudyRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalStudyRollupStore() -> any RegionalStudyRollupStore {
        return MemoryRegionalStudyRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalStudyRollupStore: RegionalStudyRollupStore {
        var inner: MemoryRegionalStudyRollupStore
        var cache: TTLCache<RegionalStudyRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalStudyRollupStore, cache: TTLCache<RegionalStudyRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalStudyRollup? {
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

        func save(_ item: RegionalStudyRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalStudyRollup] {
            return inner.list()
        }
    }

    static func newCachedRegionalStudyRollupStore(_ inner: MemoryRegionalStudyRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalStudyRollupStore {
        return CachedRegionalStudyRollupStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional study rollups. Empty fields match all.
    final class RegionalStudyRollupQuery {
        var region: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalStudyRollup) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalStudyRollup]) -> [RegionalStudyRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalStudyRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalStudyRollups(_ store: any RegionalStudyRollupStore, query: RegionalStudyRollupQuery) -> [RegionalStudyRollup] {
        return query.apply(store.list())
    }
}
