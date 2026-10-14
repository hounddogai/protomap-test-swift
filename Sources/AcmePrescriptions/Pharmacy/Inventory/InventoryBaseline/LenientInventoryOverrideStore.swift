import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps lenient inventory overrides by code.
    protocol LenientInventoryOverrideStore {
        func find(_ code: String) -> LenientInventoryOverride?
        func save(_ item: LenientInventoryOverride)
        func remove(_ code: String) -> Bool
        func list() -> [LenientInventoryOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientInventoryOverrideStore: LenientInventoryOverrideStore {
        var items: [String: LenientInventoryOverride]
        var order: [String]

        init(items: [String: LenientInventoryOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientInventoryOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientInventoryOverride) {
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

        func list() -> [LenientInventoryOverride] {
            var out: [LenientInventoryOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientInventoryOverrideStore() -> any LenientInventoryOverrideStore {
        return MemoryLenientInventoryOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientInventoryOverrideStore: LenientInventoryOverrideStore {
        var inner: MemoryLenientInventoryOverrideStore
        var cache: TTLCache<LenientInventoryOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientInventoryOverrideStore, cache: TTLCache<LenientInventoryOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientInventoryOverride? {
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

        func save(_ item: LenientInventoryOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientInventoryOverride] {
            return inner.list()
        }
    }

    static func newCachedLenientInventoryOverrideStore(_ inner: MemoryLenientInventoryOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientInventoryOverrideStore {
        return CachedLenientInventoryOverrideStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient inventory overrides. Empty fields match all.
    final class LenientInventoryOverrideQuery {
        var region: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minMargin: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientInventoryOverride) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [LenientInventoryOverride]) -> [LenientInventoryOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientInventoryOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientInventoryOverrides(_ store: any LenientInventoryOverrideStore, query: LenientInventoryOverrideQuery) -> [LenientInventoryOverride] {
        return query.apply(store.list())
    }
}
