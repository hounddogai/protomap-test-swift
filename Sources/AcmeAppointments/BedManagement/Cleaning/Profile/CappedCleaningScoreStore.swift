import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps capped cleaning scores by code.
    protocol CappedCleaningScoreStore {
        func find(_ code: String) -> CappedCleaningScore?
        func save(_ item: CappedCleaningScore)
        func remove(_ code: String) -> Bool
        func list() -> [CappedCleaningScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedCleaningScoreStore: CappedCleaningScoreStore {
        var items: [String: CappedCleaningScore]
        var order: [String]

        init(items: [String: CappedCleaningScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedCleaningScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedCleaningScore) {
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

        func list() -> [CappedCleaningScore] {
            var out: [CappedCleaningScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedCleaningScoreStore() -> any CappedCleaningScoreStore {
        return MemoryCappedCleaningScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedCleaningScoreStore: CappedCleaningScoreStore {
        var inner: MemoryCappedCleaningScoreStore
        var cache: TTLCache<CappedCleaningScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedCleaningScoreStore, cache: TTLCache<CappedCleaningScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedCleaningScore? {
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

        func save(_ item: CappedCleaningScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedCleaningScore] {
            return inner.list()
        }
    }

    static func newCachedCappedCleaningScoreStore(_ inner: MemoryCappedCleaningScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedCleaningScoreStore {
        return CachedCappedCleaningScoreStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped cleaning scores. Empty fields match all.
    final class CappedCleaningScoreQuery {
        var segment: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minRate: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedCleaningScore) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [CappedCleaningScore]) -> [CappedCleaningScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedCleaningScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedCleaningScores(_ store: any CappedCleaningScoreStore, query: CappedCleaningScoreQuery) -> [CappedCleaningScore] {
        return query.apply(store.list())
    }
}
