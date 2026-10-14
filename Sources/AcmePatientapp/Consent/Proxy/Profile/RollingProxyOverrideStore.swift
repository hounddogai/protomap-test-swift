import AcmePlatform
import Foundation

extension Consent {
    /// Keeps rolling proxy overrides by code.
    protocol RollingProxyOverrideStore {
        func find(_ code: String) -> RollingProxyOverride?
        func save(_ item: RollingProxyOverride)
        func remove(_ code: String) -> Bool
        func list() -> [RollingProxyOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingProxyOverrideStore: RollingProxyOverrideStore {
        var items: [String: RollingProxyOverride]
        var order: [String]

        init(items: [String: RollingProxyOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingProxyOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingProxyOverride) {
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

        func list() -> [RollingProxyOverride] {
            var out: [RollingProxyOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingProxyOverrideStore() -> any RollingProxyOverrideStore {
        return MemoryRollingProxyOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingProxyOverrideStore: RollingProxyOverrideStore {
        var inner: MemoryRollingProxyOverrideStore
        var cache: TTLCache<RollingProxyOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingProxyOverrideStore, cache: TTLCache<RollingProxyOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingProxyOverride? {
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

        func save(_ item: RollingProxyOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingProxyOverride] {
            return inner.list()
        }
    }

    static func newCachedRollingProxyOverrideStore(_ inner: MemoryRollingProxyOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingProxyOverrideStore {
        return CachedRollingProxyOverrideStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling proxy overrides. Empty fields match all.
    final class RollingProxyOverrideQuery {
        var name: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minRate: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingProxyOverride) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingProxyOverride]) -> [RollingProxyOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingProxyOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingProxyOverrides(_ store: any RollingProxyOverrideStore, query: RollingProxyOverrideQuery) -> [RollingProxyOverride] {
        return query.apply(store.list())
    }
}
