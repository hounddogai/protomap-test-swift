import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps follow up cycles by code.
    protocol FollowUpCycleStore {
        func find(_ code: String) -> FollowUpCycle?
        func save(_ item: FollowUpCycle)
        func remove(_ code: String) -> Bool
        func list() -> [FollowUpCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFollowUpCycleStore: FollowUpCycleStore {
        var items: [String: FollowUpCycle]
        var order: [String]

        init(items: [String: FollowUpCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FollowUpCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FollowUpCycle) {
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

        func list() -> [FollowUpCycle] {
            var out: [FollowUpCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFollowUpCycleStore() -> any FollowUpCycleStore {
        return MemoryFollowUpCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFollowUpCycleStore: FollowUpCycleStore {
        var inner: MemoryFollowUpCycleStore
        var cache: TTLCache<FollowUpCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryFollowUpCycleStore, cache: TTLCache<FollowUpCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FollowUpCycle? {
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

        func save(_ item: FollowUpCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FollowUpCycle] {
            return inner.list()
        }
    }

    static func newCachedFollowUpCycleStore(_ inner: MemoryFollowUpCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FollowUpCycleStore {
        return CachedFollowUpCycleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects follow up cycles. Empty fields match all.
    final class FollowUpCycleQuery {
        var source: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FollowUpCycle) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [FollowUpCycle]) -> [FollowUpCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FollowUpCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFollowUpCycles(_ store: any FollowUpCycleStore, query: FollowUpCycleQuery) -> [FollowUpCycle] {
        return query.apply(store.list())
    }
}
