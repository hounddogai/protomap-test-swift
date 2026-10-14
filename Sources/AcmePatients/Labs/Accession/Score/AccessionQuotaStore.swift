import AcmePlatform
import Foundation

extension Labs {
    /// Keeps accession quotas by code.
    protocol AccessionQuotaStore {
        func find(_ code: String) -> AccessionQuota?
        func save(_ item: AccessionQuota)
        func remove(_ code: String) -> Bool
        func list() -> [AccessionQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAccessionQuotaStore: AccessionQuotaStore {
        var items: [String: AccessionQuota]
        var order: [String]

        init(items: [String: AccessionQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AccessionQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AccessionQuota) {
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

        func list() -> [AccessionQuota] {
            var out: [AccessionQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAccessionQuotaStore() -> any AccessionQuotaStore {
        return MemoryAccessionQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAccessionQuotaStore: AccessionQuotaStore {
        var inner: MemoryAccessionQuotaStore
        var cache: TTLCache<AccessionQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryAccessionQuotaStore, cache: TTLCache<AccessionQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AccessionQuota? {
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

        func save(_ item: AccessionQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AccessionQuota] {
            return inner.list()
        }
    }

    static func newCachedAccessionQuotaStore(_ inner: MemoryAccessionQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AccessionQuotaStore {
        return CachedAccessionQuotaStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects accession quotas. Empty fields match all.
    final class AccessionQuotaQuery {
        var segment: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AccessionQuota) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AccessionQuota]) -> [AccessionQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AccessionQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAccessionQuotas(_ store: any AccessionQuotaStore, query: AccessionQuotaQuery) -> [AccessionQuota] {
        return query.apply(store.list())
    }
}
