import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps census scores by code.
    protocol CensusScoreStore {
        func find(_ code: String) -> CensusScore?
        func save(_ item: CensusScore)
        func remove(_ code: String) -> Bool
        func list() -> [CensusScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCensusScoreStore: CensusScoreStore {
        var items: [String: CensusScore]
        var order: [String]

        init(items: [String: CensusScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CensusScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CensusScore) {
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

        func list() -> [CensusScore] {
            var out: [CensusScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCensusScoreStore() -> any CensusScoreStore {
        return MemoryCensusScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCensusScoreStore: CensusScoreStore {
        var inner: MemoryCensusScoreStore
        var cache: TTLCache<CensusScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryCensusScoreStore, cache: TTLCache<CensusScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CensusScore? {
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

        func save(_ item: CensusScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CensusScore] {
            return inner.list()
        }
    }

    static func newCachedCensusScoreStore(_ inner: MemoryCensusScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CensusScoreStore {
        return CachedCensusScoreStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects census scores. Empty fields match all.
    final class CensusScoreQuery {
        var segment: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CensusScore) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [CensusScore]) -> [CensusScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CensusScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCensusScores(_ store: any CensusScoreStore, query: CensusScoreQuery) -> [CensusScore] {
        return query.apply(store.list())
    }
}
