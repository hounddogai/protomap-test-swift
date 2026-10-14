import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps task quotas by code.
    protocol TaskQuotaStore {
        func find(_ code: String) -> TaskQuota?
        func save(_ item: TaskQuota)
        func remove(_ code: String) -> Bool
        func list() -> [TaskQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTaskQuotaStore: TaskQuotaStore {
        var items: [String: TaskQuota]
        var order: [String]

        init(items: [String: TaskQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TaskQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TaskQuota) {
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

        func list() -> [TaskQuota] {
            var out: [TaskQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTaskQuotaStore() -> any TaskQuotaStore {
        return MemoryTaskQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTaskQuotaStore: TaskQuotaStore {
        var inner: MemoryTaskQuotaStore
        var cache: TTLCache<TaskQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryTaskQuotaStore, cache: TTLCache<TaskQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TaskQuota? {
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

        func save(_ item: TaskQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TaskQuota] {
            return inner.list()
        }
    }

    static func newCachedTaskQuotaStore(_ inner: MemoryTaskQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TaskQuotaStore {
        return CachedTaskQuotaStore(inner: inner, cache: newTTLCache(64, ttl: ttl, clock: clock), hits: 0, misses: 0)
    }

    /// Selects task quotas. Empty fields match all.
    final class TaskQuotaQuery {
        var title: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minLimit: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TaskQuota) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TaskQuota]) -> [TaskQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TaskQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTaskQuotas(_ store: any TaskQuotaStore, query: TaskQuotaQuery) -> [TaskQuota] {
        return query.apply(store.list())
    }
}
