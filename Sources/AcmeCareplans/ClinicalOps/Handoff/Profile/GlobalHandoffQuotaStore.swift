import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps global handoff quotas by code.
    protocol GlobalHandoffQuotaStore {
        func find(_ code: String) -> GlobalHandoffQuota?
        func save(_ item: GlobalHandoffQuota)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalHandoffQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalHandoffQuotaStore: GlobalHandoffQuotaStore {
        var items: [String: GlobalHandoffQuota]
        var order: [String]

        init(items: [String: GlobalHandoffQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalHandoffQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalHandoffQuota) {
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

        func list() -> [GlobalHandoffQuota] {
            var out: [GlobalHandoffQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalHandoffQuotaStore() -> any GlobalHandoffQuotaStore {
        return MemoryGlobalHandoffQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalHandoffQuotaStore: GlobalHandoffQuotaStore {
        var inner: MemoryGlobalHandoffQuotaStore
        var cache: TTLCache<GlobalHandoffQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalHandoffQuotaStore, cache: TTLCache<GlobalHandoffQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalHandoffQuota? {
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

        func save(_ item: GlobalHandoffQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalHandoffQuota] {
            return inner.list()
        }
    }

    static func newCachedGlobalHandoffQuotaStore(_ inner: MemoryGlobalHandoffQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalHandoffQuotaStore {
        return CachedGlobalHandoffQuotaStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global handoff quotas. Empty fields match all.
    final class GlobalHandoffQuotaQuery {
        var country: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minPriority: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalHandoffQuota) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalHandoffQuota]) -> [GlobalHandoffQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalHandoffQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalHandoffQuotas(_ store: any GlobalHandoffQuotaStore, query: GlobalHandoffQuotaQuery) -> [GlobalHandoffQuota] {
        return query.apply(store.list())
    }
}
