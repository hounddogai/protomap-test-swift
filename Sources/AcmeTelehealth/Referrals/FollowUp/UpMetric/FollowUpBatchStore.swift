import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps follow up batches by code.
    protocol FollowUpBatchStore {
        func find(_ code: String) -> FollowUpBatch?
        func save(_ item: FollowUpBatch)
        func remove(_ code: String) -> Bool
        func list() -> [FollowUpBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFollowUpBatchStore: FollowUpBatchStore {
        var items: [String: FollowUpBatch]
        var order: [String]

        init(items: [String: FollowUpBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FollowUpBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FollowUpBatch) {
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

        func list() -> [FollowUpBatch] {
            var out: [FollowUpBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFollowUpBatchStore() -> any FollowUpBatchStore {
        return MemoryFollowUpBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFollowUpBatchStore: FollowUpBatchStore {
        var inner: MemoryFollowUpBatchStore
        var cache: TTLCache<FollowUpBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryFollowUpBatchStore, cache: TTLCache<FollowUpBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FollowUpBatch? {
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

        func save(_ item: FollowUpBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FollowUpBatch] {
            return inner.list()
        }
    }

    static func newCachedFollowUpBatchStore(_ inner: MemoryFollowUpBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FollowUpBatchStore {
        return CachedFollowUpBatchStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects follow up batches. Empty fields match all.
    final class FollowUpBatchQuery {
        var name: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FollowUpBatch) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FollowUpBatch]) -> [FollowUpBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FollowUpBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFollowUpBatches(_ store: any FollowUpBatchStore, query: FollowUpBatchQuery) -> [FollowUpBatch] {
        return query.apply(store.list())
    }
}
