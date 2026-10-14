import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps rolling care protocol overrides by code.
    protocol RollingCareProtocolOverrideStore {
        func find(_ code: String) -> RollingCareProtocolOverride?
        func save(_ item: RollingCareProtocolOverride)
        func remove(_ code: String) -> Bool
        func list() -> [RollingCareProtocolOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingCareProtocolOverrideStore: RollingCareProtocolOverrideStore {
        var items: [String: RollingCareProtocolOverride]
        var order: [String]

        init(items: [String: RollingCareProtocolOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingCareProtocolOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingCareProtocolOverride) {
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

        func list() -> [RollingCareProtocolOverride] {
            var out: [RollingCareProtocolOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingCareProtocolOverrideStore() -> any RollingCareProtocolOverrideStore {
        return MemoryRollingCareProtocolOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingCareProtocolOverrideStore: RollingCareProtocolOverrideStore {
        var inner: MemoryRollingCareProtocolOverrideStore
        var cache: TTLCache<RollingCareProtocolOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingCareProtocolOverrideStore, cache: TTLCache<RollingCareProtocolOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingCareProtocolOverride? {
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

        func save(_ item: RollingCareProtocolOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingCareProtocolOverride] {
            return inner.list()
        }
    }

    static func newCachedRollingCareProtocolOverrideStore(_ inner: MemoryRollingCareProtocolOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingCareProtocolOverrideStore {
        return CachedRollingCareProtocolOverrideStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling care protocol overrides. Empty fields match all.
    final class RollingCareProtocolOverrideQuery {
        var country: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingCareProtocolOverride) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingCareProtocolOverride]) -> [RollingCareProtocolOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingCareProtocolOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingCareProtocolOverrides(_ store: any RollingCareProtocolOverrideStore, query: RollingCareProtocolOverrideQuery) -> [RollingCareProtocolOverride] {
        return query.apply(store.list())
    }
}
