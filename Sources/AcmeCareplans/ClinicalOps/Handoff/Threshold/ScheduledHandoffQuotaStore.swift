import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps scheduled handoff quotas by code.
    protocol ScheduledHandoffQuotaStore {
        func find(_ code: String) -> ScheduledHandoffQuota?
        func save(_ item: ScheduledHandoffQuota)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledHandoffQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledHandoffQuotaStore: ScheduledHandoffQuotaStore {
        var items: [String: ScheduledHandoffQuota]
        var order: [String]

        init(items: [String: ScheduledHandoffQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledHandoffQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledHandoffQuota) {
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

        func list() -> [ScheduledHandoffQuota] {
            var out: [ScheduledHandoffQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledHandoffQuotaStore() -> any ScheduledHandoffQuotaStore {
        return MemoryScheduledHandoffQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledHandoffQuotaStore: ScheduledHandoffQuotaStore {
        var inner: MemoryScheduledHandoffQuotaStore
        var cache: TTLCache<ScheduledHandoffQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledHandoffQuotaStore, cache: TTLCache<ScheduledHandoffQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledHandoffQuota? {
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

        func save(_ item: ScheduledHandoffQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledHandoffQuota] {
            return inner.list()
        }
    }

    static func newCachedScheduledHandoffQuotaStore(_ inner: MemoryScheduledHandoffQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledHandoffQuotaStore {
        return CachedScheduledHandoffQuotaStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled handoff quotas. Empty fields match all.
    final class ScheduledHandoffQuotaQuery {
        var name: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRetries: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledHandoffQuota) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledHandoffQuota]) -> [ScheduledHandoffQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledHandoffQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledHandoffQuotas(_ store: any ScheduledHandoffQuotaStore, query: ScheduledHandoffQuotaQuery) -> [ScheduledHandoffQuota] {
        return query.apply(store.list())
    }
}
