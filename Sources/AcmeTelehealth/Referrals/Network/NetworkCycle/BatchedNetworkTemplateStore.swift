import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps batched network templates by code.
    protocol BatchedNetworkTemplateStore {
        func find(_ code: String) -> BatchedNetworkTemplate?
        func save(_ item: BatchedNetworkTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedNetworkTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedNetworkTemplateStore: BatchedNetworkTemplateStore {
        var items: [String: BatchedNetworkTemplate]
        var order: [String]

        init(items: [String: BatchedNetworkTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedNetworkTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedNetworkTemplate) {
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

        func list() -> [BatchedNetworkTemplate] {
            var out: [BatchedNetworkTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedNetworkTemplateStore() -> any BatchedNetworkTemplateStore {
        return MemoryBatchedNetworkTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedNetworkTemplateStore: BatchedNetworkTemplateStore {
        var inner: MemoryBatchedNetworkTemplateStore
        var cache: TTLCache<BatchedNetworkTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedNetworkTemplateStore, cache: TTLCache<BatchedNetworkTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedNetworkTemplate? {
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

        func save(_ item: BatchedNetworkTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedNetworkTemplate] {
            return inner.list()
        }
    }

    static func newCachedBatchedNetworkTemplateStore(_ inner: MemoryBatchedNetworkTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedNetworkTemplateStore {
        return CachedBatchedNetworkTemplateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched network templates. Empty fields match all.
    final class BatchedNetworkTemplateQuery {
        var segment: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minRatio: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedNetworkTemplate) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedNetworkTemplate]) -> [BatchedNetworkTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedNetworkTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedNetworkTemplates(_ store: any BatchedNetworkTemplateStore, query: BatchedNetworkTemplateQuery) -> [BatchedNetworkTemplate] {
        return query.apply(store.list())
    }
}
