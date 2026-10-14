import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps recall quotas by code.
    protocol RecallQuotaStore {
        func find(_ code: String) -> RecallQuota?
        func save(_ item: RecallQuota)
        func remove(_ code: String) -> Bool
        func list() -> [RecallQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRecallQuotaStore: RecallQuotaStore {
        var items: [String: RecallQuota]
        var order: [String]

        init(items: [String: RecallQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RecallQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RecallQuota) {
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

        func list() -> [RecallQuota] {
            var out: [RecallQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRecallQuotaStore() -> any RecallQuotaStore {
        return MemoryRecallQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRecallQuotaStore: RecallQuotaStore {
        var inner: MemoryRecallQuotaStore
        var cache: TTLCache<RecallQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryRecallQuotaStore, cache: TTLCache<RecallQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RecallQuota? {
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

        func save(_ item: RecallQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RecallQuota] {
            return inner.list()
        }
    }

    static func newCachedRecallQuotaStore(_ inner: MemoryRecallQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RecallQuotaStore {
        return CachedRecallQuotaStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects recall quotas. Empty fields match all.
    final class RecallQuotaQuery {
        var category: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RecallQuota) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RecallQuota]) -> [RecallQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RecallQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRecallQuotas(_ store: any RecallQuotaStore, query: RecallQuotaQuery) -> [RecallQuota] {
        return query.apply(store.list())
    }
}
