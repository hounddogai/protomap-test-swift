import AcmePlatform
import Foundation

extension Labs {
    /// Keeps rolling panel quotas by code.
    protocol RollingPanelQuotaStore {
        func find(_ code: String) -> RollingPanelQuota?
        func save(_ item: RollingPanelQuota)
        func remove(_ code: String) -> Bool
        func list() -> [RollingPanelQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingPanelQuotaStore: RollingPanelQuotaStore {
        var items: [String: RollingPanelQuota]
        var order: [String]

        init(items: [String: RollingPanelQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingPanelQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingPanelQuota) {
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

        func list() -> [RollingPanelQuota] {
            var out: [RollingPanelQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingPanelQuotaStore() -> any RollingPanelQuotaStore {
        return MemoryRollingPanelQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingPanelQuotaStore: RollingPanelQuotaStore {
        var inner: MemoryRollingPanelQuotaStore
        var cache: TTLCache<RollingPanelQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingPanelQuotaStore, cache: TTLCache<RollingPanelQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingPanelQuota? {
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

        func save(_ item: RollingPanelQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingPanelQuota] {
            return inner.list()
        }
    }

    static func newCachedRollingPanelQuotaStore(_ inner: MemoryRollingPanelQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingPanelQuotaStore {
        return CachedRollingPanelQuotaStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling panel quotas. Empty fields match all.
    final class RollingPanelQuotaQuery {
        var region: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingPanelQuota) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [RollingPanelQuota]) -> [RollingPanelQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingPanelQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingPanelQuotas(_ store: any RollingPanelQuotaStore, query: RollingPanelQuotaQuery) -> [RollingPanelQuota] {
        return query.apply(store.list())
    }
}
