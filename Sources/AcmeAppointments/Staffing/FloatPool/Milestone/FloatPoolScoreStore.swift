import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps float pool scores by code.
    protocol FloatPoolScoreStore {
        func find(_ code: String) -> FloatPoolScore?
        func save(_ item: FloatPoolScore)
        func remove(_ code: String) -> Bool
        func list() -> [FloatPoolScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFloatPoolScoreStore: FloatPoolScoreStore {
        var items: [String: FloatPoolScore]
        var order: [String]

        init(items: [String: FloatPoolScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FloatPoolScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FloatPoolScore) {
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

        func list() -> [FloatPoolScore] {
            var out: [FloatPoolScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFloatPoolScoreStore() -> any FloatPoolScoreStore {
        return MemoryFloatPoolScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFloatPoolScoreStore: FloatPoolScoreStore {
        var inner: MemoryFloatPoolScoreStore
        var cache: TTLCache<FloatPoolScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryFloatPoolScoreStore, cache: TTLCache<FloatPoolScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FloatPoolScore? {
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

        func save(_ item: FloatPoolScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FloatPoolScore] {
            return inner.list()
        }
    }

    static func newCachedFloatPoolScoreStore(_ inner: MemoryFloatPoolScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FloatPoolScoreStore {
        return CachedFloatPoolScoreStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects float pool scores. Empty fields match all.
    final class FloatPoolScoreQuery {
        var label: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCost: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FloatPoolScore) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FloatPoolScore]) -> [FloatPoolScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FloatPoolScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFloatPoolScores(_ store: any FloatPoolScoreStore, query: FloatPoolScoreQuery) -> [FloatPoolScore] {
        return query.apply(store.list())
    }
}
