import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps tiered priority scores by code.
    protocol TieredPriorityScoreStore {
        func find(_ code: String) -> TieredPriorityScore?
        func save(_ item: TieredPriorityScore)
        func remove(_ code: String) -> Bool
        func list() -> [TieredPriorityScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredPriorityScoreStore: TieredPriorityScoreStore {
        var items: [String: TieredPriorityScore]
        var order: [String]

        init(items: [String: TieredPriorityScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredPriorityScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredPriorityScore) {
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

        func list() -> [TieredPriorityScore] {
            var out: [TieredPriorityScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredPriorityScoreStore() -> any TieredPriorityScoreStore {
        return MemoryTieredPriorityScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredPriorityScoreStore: TieredPriorityScoreStore {
        var inner: MemoryTieredPriorityScoreStore
        var cache: TTLCache<TieredPriorityScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredPriorityScoreStore, cache: TTLCache<TieredPriorityScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredPriorityScore? {
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

        func save(_ item: TieredPriorityScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredPriorityScore] {
            return inner.list()
        }
    }

    static func newCachedTieredPriorityScoreStore(_ inner: MemoryTieredPriorityScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredPriorityScoreStore {
        return CachedTieredPriorityScoreStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered priority scores. Empty fields match all.
    final class TieredPriorityScoreQuery {
        var facility: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredPriorityScore) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredPriorityScore]) -> [TieredPriorityScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredPriorityScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredPriorityScores(_ store: any TieredPriorityScoreStore, query: TieredPriorityScoreQuery) -> [TieredPriorityScore] {
        return query.apply(store.list())
    }
}
