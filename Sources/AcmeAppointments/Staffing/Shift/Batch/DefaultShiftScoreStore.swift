import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps default shift scores by code.
    protocol DefaultShiftScoreStore {
        func find(_ code: String) -> DefaultShiftScore?
        func save(_ item: DefaultShiftScore)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultShiftScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultShiftScoreStore: DefaultShiftScoreStore {
        var items: [String: DefaultShiftScore]
        var order: [String]

        init(items: [String: DefaultShiftScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultShiftScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultShiftScore) {
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

        func list() -> [DefaultShiftScore] {
            var out: [DefaultShiftScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultShiftScoreStore() -> any DefaultShiftScoreStore {
        return MemoryDefaultShiftScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultShiftScoreStore: DefaultShiftScoreStore {
        var inner: MemoryDefaultShiftScoreStore
        var cache: TTLCache<DefaultShiftScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultShiftScoreStore, cache: TTLCache<DefaultShiftScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultShiftScore? {
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

        func save(_ item: DefaultShiftScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultShiftScore] {
            return inner.list()
        }
    }

    static func newCachedDefaultShiftScoreStore(_ inner: MemoryDefaultShiftScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultShiftScoreStore {
        return CachedDefaultShiftScoreStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default shift scores. Empty fields match all.
    final class DefaultShiftScoreQuery {
        var source: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minRate: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultShiftScore) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultShiftScore]) -> [DefaultShiftScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultShiftScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultShiftScores(_ store: any DefaultShiftScoreStore, query: DefaultShiftScoreQuery) -> [DefaultShiftScore] {
        return query.apply(store.list())
    }
}
