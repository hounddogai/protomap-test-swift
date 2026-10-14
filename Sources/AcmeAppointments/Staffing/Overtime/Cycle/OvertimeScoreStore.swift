import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps overtime scores by code.
    protocol OvertimeScoreStore {
        func find(_ code: String) -> OvertimeScore?
        func save(_ item: OvertimeScore)
        func remove(_ code: String) -> Bool
        func list() -> [OvertimeScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOvertimeScoreStore: OvertimeScoreStore {
        var items: [String: OvertimeScore]
        var order: [String]

        init(items: [String: OvertimeScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OvertimeScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OvertimeScore) {
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

        func list() -> [OvertimeScore] {
            var out: [OvertimeScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOvertimeScoreStore() -> any OvertimeScoreStore {
        return MemoryOvertimeScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOvertimeScoreStore: OvertimeScoreStore {
        var inner: MemoryOvertimeScoreStore
        var cache: TTLCache<OvertimeScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryOvertimeScoreStore, cache: TTLCache<OvertimeScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OvertimeScore? {
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

        func save(_ item: OvertimeScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OvertimeScore] {
            return inner.list()
        }
    }

    static func newCachedOvertimeScoreStore(_ inner: MemoryOvertimeScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OvertimeScoreStore {
        return CachedOvertimeScoreStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects overtime scores. Empty fields match all.
    final class OvertimeScoreQuery {
        var channel: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minWeight: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OvertimeScore) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OvertimeScore]) -> [OvertimeScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OvertimeScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOvertimeScores(_ store: any OvertimeScoreStore, query: OvertimeScoreQuery) -> [OvertimeScore] {
        return query.apply(store.list())
    }
}
