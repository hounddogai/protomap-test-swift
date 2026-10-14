import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps worklist quotas by code.
    protocol WorklistQuotaStore {
        func find(_ code: String) -> WorklistQuota?
        func save(_ item: WorklistQuota)
        func remove(_ code: String) -> Bool
        func list() -> [WorklistQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWorklistQuotaStore: WorklistQuotaStore {
        var items: [String: WorklistQuota]
        var order: [String]

        init(items: [String: WorklistQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WorklistQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WorklistQuota) {
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

        func list() -> [WorklistQuota] {
            var out: [WorklistQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWorklistQuotaStore() -> any WorklistQuotaStore {
        return MemoryWorklistQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWorklistQuotaStore: WorklistQuotaStore {
        var inner: MemoryWorklistQuotaStore
        var cache: TTLCache<WorklistQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryWorklistQuotaStore, cache: TTLCache<WorklistQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WorklistQuota? {
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

        func save(_ item: WorklistQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WorklistQuota] {
            return inner.list()
        }
    }

    static func newCachedWorklistQuotaStore(_ inner: MemoryWorklistQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WorklistQuotaStore {
        return CachedWorklistQuotaStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects worklist quotas. Empty fields match all.
    final class WorklistQuotaQuery {
        var title: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minAmount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WorklistQuota) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WorklistQuota]) -> [WorklistQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WorklistQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWorklistQuotas(_ store: any WorklistQuotaStore, query: WorklistQuotaQuery) -> [WorklistQuota] {
        return query.apply(store.list())
    }
}
