import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps fallback remittance targets by code.
    protocol FallbackRemittanceTargetStore {
        func find(_ code: String) -> FallbackRemittanceTarget?
        func save(_ item: FallbackRemittanceTarget)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackRemittanceTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackRemittanceTargetStore: FallbackRemittanceTargetStore {
        var items: [String: FallbackRemittanceTarget]
        var order: [String]

        init(items: [String: FallbackRemittanceTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackRemittanceTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackRemittanceTarget) {
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

        func list() -> [FallbackRemittanceTarget] {
            var out: [FallbackRemittanceTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackRemittanceTargetStore() -> any FallbackRemittanceTargetStore {
        return MemoryFallbackRemittanceTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackRemittanceTargetStore: FallbackRemittanceTargetStore {
        var inner: MemoryFallbackRemittanceTargetStore
        var cache: TTLCache<FallbackRemittanceTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackRemittanceTargetStore, cache: TTLCache<FallbackRemittanceTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackRemittanceTarget? {
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

        func save(_ item: FallbackRemittanceTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackRemittanceTarget] {
            return inner.list()
        }
    }

    static func newCachedFallbackRemittanceTargetStore(_ inner: MemoryFallbackRemittanceTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackRemittanceTargetStore {
        return CachedFallbackRemittanceTargetStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback remittance targets. Empty fields match all.
    final class FallbackRemittanceTargetQuery {
        var region: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackRemittanceTarget) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackRemittanceTarget]) -> [FallbackRemittanceTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackRemittanceTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackRemittanceTargets(_ store: any FallbackRemittanceTargetStore, query: FallbackRemittanceTargetQuery) -> [FallbackRemittanceTarget] {
        return query.apply(store.list())
    }
}
