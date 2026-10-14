import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps read quotas by code.
    protocol ReadQuotaStore {
        func find(_ code: String) -> ReadQuota?
        func save(_ item: ReadQuota)
        func remove(_ code: String) -> Bool
        func list() -> [ReadQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReadQuotaStore: ReadQuotaStore {
        var items: [String: ReadQuota]
        var order: [String]

        init(items: [String: ReadQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReadQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReadQuota) {
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

        func list() -> [ReadQuota] {
            var out: [ReadQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReadQuotaStore() -> any ReadQuotaStore {
        return MemoryReadQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReadQuotaStore: ReadQuotaStore {
        var inner: MemoryReadQuotaStore
        var cache: TTLCache<ReadQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryReadQuotaStore, cache: TTLCache<ReadQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReadQuota? {
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

        func save(_ item: ReadQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReadQuota] {
            return inner.list()
        }
    }

    static func newCachedReadQuotaStore(_ inner: MemoryReadQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReadQuotaStore {
        return CachedReadQuotaStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects read quotas. Empty fields match all.
    final class ReadQuotaQuery {
        var title: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReadQuota) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReadQuota]) -> [ReadQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReadQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReadQuotas(_ store: any ReadQuotaStore, query: ReadQuotaQuery) -> [ReadQuota] {
        return query.apply(store.list())
    }
}
