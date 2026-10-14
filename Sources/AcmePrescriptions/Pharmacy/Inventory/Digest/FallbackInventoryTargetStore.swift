import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps fallback inventory targets by code.
    protocol FallbackInventoryTargetStore {
        func find(_ code: String) -> FallbackInventoryTarget?
        func save(_ item: FallbackInventoryTarget)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackInventoryTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackInventoryTargetStore: FallbackInventoryTargetStore {
        var items: [String: FallbackInventoryTarget]
        var order: [String]

        init(items: [String: FallbackInventoryTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackInventoryTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackInventoryTarget) {
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

        func list() -> [FallbackInventoryTarget] {
            var out: [FallbackInventoryTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackInventoryTargetStore() -> any FallbackInventoryTargetStore {
        return MemoryFallbackInventoryTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackInventoryTargetStore: FallbackInventoryTargetStore {
        var inner: MemoryFallbackInventoryTargetStore
        var cache: TTLCache<FallbackInventoryTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackInventoryTargetStore, cache: TTLCache<FallbackInventoryTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackInventoryTarget? {
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

        func save(_ item: FallbackInventoryTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackInventoryTarget] {
            return inner.list()
        }
    }

    static func newCachedFallbackInventoryTargetStore(_ inner: MemoryFallbackInventoryTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackInventoryTargetStore {
        return CachedFallbackInventoryTargetStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback inventory targets. Empty fields match all.
    final class FallbackInventoryTargetQuery {
        var source: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackInventoryTarget) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackInventoryTarget]) -> [FallbackInventoryTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackInventoryTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackInventoryTargets(_ store: any FallbackInventoryTargetStore, query: FallbackInventoryTargetQuery) -> [FallbackInventoryTarget] {
        return query.apply(store.list())
    }
}
