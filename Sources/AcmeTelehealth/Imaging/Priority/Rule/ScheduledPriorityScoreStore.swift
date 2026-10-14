import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps scheduled priority scores by code.
    protocol ScheduledPriorityScoreStore {
        func find(_ code: String) -> ScheduledPriorityScore?
        func save(_ item: ScheduledPriorityScore)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledPriorityScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledPriorityScoreStore: ScheduledPriorityScoreStore {
        var items: [String: ScheduledPriorityScore]
        var order: [String]

        init(items: [String: ScheduledPriorityScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledPriorityScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledPriorityScore) {
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

        func list() -> [ScheduledPriorityScore] {
            var out: [ScheduledPriorityScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledPriorityScoreStore() -> any ScheduledPriorityScoreStore {
        return MemoryScheduledPriorityScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledPriorityScoreStore: ScheduledPriorityScoreStore {
        var inner: MemoryScheduledPriorityScoreStore
        var cache: TTLCache<ScheduledPriorityScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledPriorityScoreStore, cache: TTLCache<ScheduledPriorityScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledPriorityScore? {
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

        func save(_ item: ScheduledPriorityScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledPriorityScore] {
            return inner.list()
        }
    }

    static func newCachedScheduledPriorityScoreStore(_ inner: MemoryScheduledPriorityScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledPriorityScoreStore {
        return CachedScheduledPriorityScoreStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled priority scores. Empty fields match all.
    final class ScheduledPriorityScoreQuery {
        var label: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledPriorityScore) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledPriorityScore]) -> [ScheduledPriorityScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledPriorityScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledPriorityScores(_ store: any ScheduledPriorityScoreStore, query: ScheduledPriorityScoreQuery) -> [ScheduledPriorityScore] {
        return query.apply(store.list())
    }
}
