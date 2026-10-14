import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps capped denial targets by code.
    protocol CappedDenialTargetStore {
        func find(_ code: String) -> CappedDenialTarget?
        func save(_ item: CappedDenialTarget)
        func remove(_ code: String) -> Bool
        func list() -> [CappedDenialTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedDenialTargetStore: CappedDenialTargetStore {
        var items: [String: CappedDenialTarget]
        var order: [String]

        init(items: [String: CappedDenialTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedDenialTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedDenialTarget) {
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

        func list() -> [CappedDenialTarget] {
            var out: [CappedDenialTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedDenialTargetStore() -> any CappedDenialTargetStore {
        return MemoryCappedDenialTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedDenialTargetStore: CappedDenialTargetStore {
        var inner: MemoryCappedDenialTargetStore
        var cache: TTLCache<CappedDenialTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedDenialTargetStore, cache: TTLCache<CappedDenialTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedDenialTarget? {
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

        func save(_ item: CappedDenialTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedDenialTarget] {
            return inner.list()
        }
    }

    static func newCachedCappedDenialTargetStore(_ inner: MemoryCappedDenialTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedDenialTargetStore {
        return CachedCappedDenialTargetStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped denial targets. Empty fields match all.
    final class CappedDenialTargetQuery {
        var region: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minAmount: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedDenialTarget) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedDenialTarget]) -> [CappedDenialTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedDenialTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedDenialTargets(_ store: any CappedDenialTargetStore, query: CappedDenialTargetQuery) -> [CappedDenialTarget] {
        return query.apply(store.list())
    }
}
