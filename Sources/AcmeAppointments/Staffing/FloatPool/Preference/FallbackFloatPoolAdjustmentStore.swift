import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps fallback float pool adjustments by code.
    protocol FallbackFloatPoolAdjustmentStore {
        func find(_ code: String) -> FallbackFloatPoolAdjustment?
        func save(_ item: FallbackFloatPoolAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackFloatPoolAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackFloatPoolAdjustmentStore: FallbackFloatPoolAdjustmentStore {
        var items: [String: FallbackFloatPoolAdjustment]
        var order: [String]

        init(items: [String: FallbackFloatPoolAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackFloatPoolAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackFloatPoolAdjustment) {
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

        func list() -> [FallbackFloatPoolAdjustment] {
            var out: [FallbackFloatPoolAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackFloatPoolAdjustmentStore() -> any FallbackFloatPoolAdjustmentStore {
        return MemoryFallbackFloatPoolAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackFloatPoolAdjustmentStore: FallbackFloatPoolAdjustmentStore {
        var inner: MemoryFallbackFloatPoolAdjustmentStore
        var cache: TTLCache<FallbackFloatPoolAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackFloatPoolAdjustmentStore, cache: TTLCache<FallbackFloatPoolAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackFloatPoolAdjustment? {
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

        func save(_ item: FallbackFloatPoolAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackFloatPoolAdjustment] {
            return inner.list()
        }
    }

    static func newCachedFallbackFloatPoolAdjustmentStore(_ inner: MemoryFallbackFloatPoolAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackFloatPoolAdjustmentStore {
        return CachedFallbackFloatPoolAdjustmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback float pool adjustments. Empty fields match all.
    final class FallbackFloatPoolAdjustmentQuery {
        var category: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minVersion: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackFloatPoolAdjustment) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackFloatPoolAdjustment]) -> [FallbackFloatPoolAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackFloatPoolAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackFloatPoolAdjustments(_ store: any FallbackFloatPoolAdjustmentStore, query: FallbackFloatPoolAdjustmentQuery) -> [FallbackFloatPoolAdjustment] {
        return query.apply(store.list())
    }
}
