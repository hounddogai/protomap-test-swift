import AcmePlatform
import Foundation

extension Consent {
    /// Keeps seasonal proxy targets by code.
    protocol SeasonalProxyTargetStore {
        func find(_ code: String) -> SeasonalProxyTarget?
        func save(_ item: SeasonalProxyTarget)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalProxyTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalProxyTargetStore: SeasonalProxyTargetStore {
        var items: [String: SeasonalProxyTarget]
        var order: [String]

        init(items: [String: SeasonalProxyTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalProxyTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalProxyTarget) {
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

        func list() -> [SeasonalProxyTarget] {
            var out: [SeasonalProxyTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalProxyTargetStore() -> any SeasonalProxyTargetStore {
        return MemorySeasonalProxyTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalProxyTargetStore: SeasonalProxyTargetStore {
        var inner: MemorySeasonalProxyTargetStore
        var cache: TTLCache<SeasonalProxyTarget>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalProxyTargetStore, cache: TTLCache<SeasonalProxyTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalProxyTarget? {
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

        func save(_ item: SeasonalProxyTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalProxyTarget] {
            return inner.list()
        }
    }

    static func newCachedSeasonalProxyTargetStore(_ inner: MemorySeasonalProxyTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalProxyTargetStore {
        return CachedSeasonalProxyTargetStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal proxy targets. Empty fields match all.
    final class SeasonalProxyTargetQuery {
        var name: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalProxyTarget) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalProxyTarget]) -> [SeasonalProxyTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalProxyTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalProxyTargets(_ store: any SeasonalProxyTargetStore, query: SeasonalProxyTargetQuery) -> [SeasonalProxyTarget] {
        return query.apply(store.list())
    }
}
