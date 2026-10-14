import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps regional float pool overrides by code.
    protocol RegionalFloatPoolOverrideStore {
        func find(_ code: String) -> RegionalFloatPoolOverride?
        func save(_ item: RegionalFloatPoolOverride)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalFloatPoolOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalFloatPoolOverrideStore: RegionalFloatPoolOverrideStore {
        var items: [String: RegionalFloatPoolOverride]
        var order: [String]

        init(items: [String: RegionalFloatPoolOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalFloatPoolOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalFloatPoolOverride) {
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

        func list() -> [RegionalFloatPoolOverride] {
            var out: [RegionalFloatPoolOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalFloatPoolOverrideStore() -> any RegionalFloatPoolOverrideStore {
        return MemoryRegionalFloatPoolOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalFloatPoolOverrideStore: RegionalFloatPoolOverrideStore {
        var inner: MemoryRegionalFloatPoolOverrideStore
        var cache: TTLCache<RegionalFloatPoolOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalFloatPoolOverrideStore, cache: TTLCache<RegionalFloatPoolOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalFloatPoolOverride? {
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

        func save(_ item: RegionalFloatPoolOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalFloatPoolOverride] {
            return inner.list()
        }
    }

    static func newCachedRegionalFloatPoolOverrideStore(_ inner: MemoryRegionalFloatPoolOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalFloatPoolOverrideStore {
        return CachedRegionalFloatPoolOverrideStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional float pool overrides. Empty fields match all.
    final class RegionalFloatPoolOverrideQuery {
        var category: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalFloatPoolOverride) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalFloatPoolOverride]) -> [RegionalFloatPoolOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalFloatPoolOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalFloatPoolOverrides(_ store: any RegionalFloatPoolOverrideStore, query: RegionalFloatPoolOverrideQuery) -> [RegionalFloatPoolOverride] {
        return query.apply(store.list())
    }
}
