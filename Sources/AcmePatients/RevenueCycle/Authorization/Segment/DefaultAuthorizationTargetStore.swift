import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps default authorization targets by code.
    protocol DefaultAuthorizationTargetStore {
        func find(_ code: String) -> DefaultAuthorizationTarget?
        func save(_ item: DefaultAuthorizationTarget)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultAuthorizationTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultAuthorizationTargetStore: DefaultAuthorizationTargetStore {
        var items: [String: DefaultAuthorizationTarget]
        var order: [String]

        init(items: [String: DefaultAuthorizationTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultAuthorizationTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultAuthorizationTarget) {
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

        func list() -> [DefaultAuthorizationTarget] {
            var out: [DefaultAuthorizationTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultAuthorizationTargetStore() -> any DefaultAuthorizationTargetStore {
        return MemoryDefaultAuthorizationTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultAuthorizationTargetStore: DefaultAuthorizationTargetStore {
        var inner: MemoryDefaultAuthorizationTargetStore
        var cache: TTLCache<DefaultAuthorizationTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultAuthorizationTargetStore, cache: TTLCache<DefaultAuthorizationTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultAuthorizationTarget? {
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

        func save(_ item: DefaultAuthorizationTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultAuthorizationTarget] {
            return inner.list()
        }
    }

    static func newCachedDefaultAuthorizationTargetStore(_ inner: MemoryDefaultAuthorizationTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultAuthorizationTargetStore {
        return CachedDefaultAuthorizationTargetStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default authorization targets. Empty fields match all.
    final class DefaultAuthorizationTargetQuery {
        var ward: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minRatio: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultAuthorizationTarget) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultAuthorizationTarget]) -> [DefaultAuthorizationTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultAuthorizationTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultAuthorizationTargets(_ store: any DefaultAuthorizationTargetStore, query: DefaultAuthorizationTargetQuery) -> [DefaultAuthorizationTarget] {
        return query.apply(store.list())
    }
}
