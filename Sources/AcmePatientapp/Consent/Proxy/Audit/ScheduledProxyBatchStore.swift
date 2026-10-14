import AcmePlatform
import Foundation

extension Consent {
    /// Keeps scheduled proxy batches by code.
    protocol ScheduledProxyBatchStore {
        func find(_ code: String) -> ScheduledProxyBatch?
        func save(_ item: ScheduledProxyBatch)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledProxyBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledProxyBatchStore: ScheduledProxyBatchStore {
        var items: [String: ScheduledProxyBatch]
        var order: [String]

        init(items: [String: ScheduledProxyBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledProxyBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledProxyBatch) {
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

        func list() -> [ScheduledProxyBatch] {
            var out: [ScheduledProxyBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledProxyBatchStore() -> any ScheduledProxyBatchStore {
        return MemoryScheduledProxyBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledProxyBatchStore: ScheduledProxyBatchStore {
        var inner: MemoryScheduledProxyBatchStore
        var cache: TTLCache<ScheduledProxyBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledProxyBatchStore, cache: TTLCache<ScheduledProxyBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledProxyBatch? {
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

        func save(_ item: ScheduledProxyBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledProxyBatch] {
            return inner.list()
        }
    }

    static func newCachedScheduledProxyBatchStore(_ inner: MemoryScheduledProxyBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledProxyBatchStore {
        return CachedScheduledProxyBatchStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled proxy batches. Empty fields match all.
    final class ScheduledProxyBatchQuery {
        var country: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minBudget: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledProxyBatch) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledProxyBatch]) -> [ScheduledProxyBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledProxyBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledProxyBatches(_ store: any ScheduledProxyBatchStore, query: ScheduledProxyBatchQuery) -> [ScheduledProxyBatch] {
        return query.apply(store.list())
    }
}
