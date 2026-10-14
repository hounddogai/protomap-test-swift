import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps priority quotas by code.
    protocol PriorityQuotaStore {
        func find(_ code: String) -> PriorityQuota?
        func save(_ item: PriorityQuota)
        func remove(_ code: String) -> Bool
        func list() -> [PriorityQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPriorityQuotaStore: PriorityQuotaStore {
        var items: [String: PriorityQuota]
        var order: [String]

        init(items: [String: PriorityQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PriorityQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PriorityQuota) {
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

        func list() -> [PriorityQuota] {
            var out: [PriorityQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPriorityQuotaStore() -> any PriorityQuotaStore {
        return MemoryPriorityQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPriorityQuotaStore: PriorityQuotaStore {
        var inner: MemoryPriorityQuotaStore
        var cache: TTLCache<PriorityQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryPriorityQuotaStore, cache: TTLCache<PriorityQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PriorityQuota? {
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

        func save(_ item: PriorityQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PriorityQuota] {
            return inner.list()
        }
    }

    static func newCachedPriorityQuotaStore(_ inner: MemoryPriorityQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PriorityQuotaStore {
        return CachedPriorityQuotaStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects priority quotas. Empty fields match all.
    final class PriorityQuotaQuery {
        var label: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minPriority: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PriorityQuota) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [PriorityQuota]) -> [PriorityQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PriorityQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPriorityQuotas(_ store: any PriorityQuotaStore, query: PriorityQuotaQuery) -> [PriorityQuota] {
        return query.apply(store.list())
    }
}
