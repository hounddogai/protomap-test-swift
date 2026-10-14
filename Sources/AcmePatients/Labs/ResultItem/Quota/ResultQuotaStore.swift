import AcmePlatform
import Foundation

extension Labs {
    /// Keeps result quotas by code.
    protocol ResultQuotaStore {
        func find(_ code: String) -> ResultQuota?
        func save(_ item: ResultQuota)
        func remove(_ code: String) -> Bool
        func list() -> [ResultQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryResultQuotaStore: ResultQuotaStore {
        var items: [String: ResultQuota]
        var order: [String]

        init(items: [String: ResultQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ResultQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ResultQuota) {
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

        func list() -> [ResultQuota] {
            var out: [ResultQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryResultQuotaStore() -> any ResultQuotaStore {
        return MemoryResultQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedResultQuotaStore: ResultQuotaStore {
        var inner: MemoryResultQuotaStore
        var cache: TTLCache<ResultQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryResultQuotaStore, cache: TTLCache<ResultQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ResultQuota? {
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

        func save(_ item: ResultQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ResultQuota] {
            return inner.list()
        }
    }

    static func newCachedResultQuotaStore(_ inner: MemoryResultQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ResultQuotaStore {
        return CachedResultQuotaStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects result quotas. Empty fields match all.
    final class ResultQuotaQuery {
        var channel: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minVersion: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ResultQuota) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ResultQuota]) -> [ResultQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ResultQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findResultQuotas(_ store: any ResultQuotaStore, query: ResultQuotaQuery) -> [ResultQuota] {
        return query.apply(store.list())
    }
}
