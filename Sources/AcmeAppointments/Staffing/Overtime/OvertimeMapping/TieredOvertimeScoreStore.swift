import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps tiered overtime scores by code.
    protocol TieredOvertimeScoreStore {
        func find(_ code: String) -> TieredOvertimeScore?
        func save(_ item: TieredOvertimeScore)
        func remove(_ code: String) -> Bool
        func list() -> [TieredOvertimeScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredOvertimeScoreStore: TieredOvertimeScoreStore {
        var items: [String: TieredOvertimeScore]
        var order: [String]

        init(items: [String: TieredOvertimeScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredOvertimeScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredOvertimeScore) {
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

        func list() -> [TieredOvertimeScore] {
            var out: [TieredOvertimeScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredOvertimeScoreStore() -> any TieredOvertimeScoreStore {
        return MemoryTieredOvertimeScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredOvertimeScoreStore: TieredOvertimeScoreStore {
        var inner: MemoryTieredOvertimeScoreStore
        var cache: TTLCache<TieredOvertimeScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredOvertimeScoreStore, cache: TTLCache<TieredOvertimeScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredOvertimeScore? {
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

        func save(_ item: TieredOvertimeScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredOvertimeScore] {
            return inner.list()
        }
    }

    static func newCachedTieredOvertimeScoreStore(_ inner: MemoryTieredOvertimeScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredOvertimeScoreStore {
        return CachedTieredOvertimeScoreStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered overtime scores. Empty fields match all.
    final class TieredOvertimeScoreQuery {
        var channel: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minLimit: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredOvertimeScore) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [TieredOvertimeScore]) -> [TieredOvertimeScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredOvertimeScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredOvertimeScores(_ store: any TieredOvertimeScoreStore, query: TieredOvertimeScoreQuery) -> [TieredOvertimeScore] {
        return query.apply(store.list())
    }
}
