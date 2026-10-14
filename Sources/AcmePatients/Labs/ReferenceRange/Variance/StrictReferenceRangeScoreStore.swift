import AcmePlatform
import Foundation

extension Labs {
    /// Keeps strict reference range scores by code.
    protocol StrictReferenceRangeScoreStore {
        func find(_ code: String) -> StrictReferenceRangeScore?
        func save(_ item: StrictReferenceRangeScore)
        func remove(_ code: String) -> Bool
        func list() -> [StrictReferenceRangeScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictReferenceRangeScoreStore: StrictReferenceRangeScoreStore {
        var items: [String: StrictReferenceRangeScore]
        var order: [String]

        init(items: [String: StrictReferenceRangeScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictReferenceRangeScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictReferenceRangeScore) {
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

        func list() -> [StrictReferenceRangeScore] {
            var out: [StrictReferenceRangeScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictReferenceRangeScoreStore() -> any StrictReferenceRangeScoreStore {
        return MemoryStrictReferenceRangeScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictReferenceRangeScoreStore: StrictReferenceRangeScoreStore {
        var inner: MemoryStrictReferenceRangeScoreStore
        var cache: TTLCache<StrictReferenceRangeScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictReferenceRangeScoreStore, cache: TTLCache<StrictReferenceRangeScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictReferenceRangeScore? {
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

        func save(_ item: StrictReferenceRangeScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictReferenceRangeScore] {
            return inner.list()
        }
    }

    static func newCachedStrictReferenceRangeScoreStore(_ inner: MemoryStrictReferenceRangeScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictReferenceRangeScoreStore {
        return CachedStrictReferenceRangeScoreStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict reference range scores. Empty fields match all.
    final class StrictReferenceRangeScoreQuery {
        var label: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minBudget: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictReferenceRangeScore) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictReferenceRangeScore]) -> [StrictReferenceRangeScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictReferenceRangeScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictReferenceRangeScores(_ store: any StrictReferenceRangeScoreStore, query: StrictReferenceRangeScoreQuery) -> [StrictReferenceRangeScore] {
        return query.apply(store.list())
    }
}
