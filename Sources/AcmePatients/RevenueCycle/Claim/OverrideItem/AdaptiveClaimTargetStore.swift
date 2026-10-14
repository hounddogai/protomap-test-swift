import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps adaptive claim targets by code.
    protocol AdaptiveClaimTargetStore {
        func find(_ code: String) -> AdaptiveClaimTarget?
        func save(_ item: AdaptiveClaimTarget)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveClaimTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveClaimTargetStore: AdaptiveClaimTargetStore {
        var items: [String: AdaptiveClaimTarget]
        var order: [String]

        init(items: [String: AdaptiveClaimTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveClaimTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveClaimTarget) {
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

        func list() -> [AdaptiveClaimTarget] {
            var out: [AdaptiveClaimTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveClaimTargetStore() -> any AdaptiveClaimTargetStore {
        return MemoryAdaptiveClaimTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveClaimTargetStore: AdaptiveClaimTargetStore {
        var inner: MemoryAdaptiveClaimTargetStore
        var cache: TTLCache<AdaptiveClaimTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveClaimTargetStore, cache: TTLCache<AdaptiveClaimTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveClaimTarget? {
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

        func save(_ item: AdaptiveClaimTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveClaimTarget] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveClaimTargetStore(_ inner: MemoryAdaptiveClaimTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveClaimTargetStore {
        return CachedAdaptiveClaimTargetStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive claim targets. Empty fields match all.
    final class AdaptiveClaimTargetQuery {
        var name: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveClaimTarget) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [AdaptiveClaimTarget]) -> [AdaptiveClaimTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveClaimTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveClaimTargets(_ store: any AdaptiveClaimTargetStore, query: AdaptiveClaimTargetQuery) -> [AdaptiveClaimTarget] {
        return query.apply(store.list())
    }
}
