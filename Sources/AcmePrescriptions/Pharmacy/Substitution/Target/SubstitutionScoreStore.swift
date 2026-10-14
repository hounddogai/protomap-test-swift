import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps substitution scores by code.
    protocol SubstitutionScoreStore {
        func find(_ code: String) -> SubstitutionScore?
        func save(_ item: SubstitutionScore)
        func remove(_ code: String) -> Bool
        func list() -> [SubstitutionScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySubstitutionScoreStore: SubstitutionScoreStore {
        var items: [String: SubstitutionScore]
        var order: [String]

        init(items: [String: SubstitutionScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SubstitutionScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SubstitutionScore) {
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

        func list() -> [SubstitutionScore] {
            var out: [SubstitutionScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySubstitutionScoreStore() -> any SubstitutionScoreStore {
        return MemorySubstitutionScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSubstitutionScoreStore: SubstitutionScoreStore {
        var inner: MemorySubstitutionScoreStore
        var cache: TTLCache<SubstitutionScore>
        var hits: Int
        var misses: Int

        init(inner: MemorySubstitutionScoreStore, cache: TTLCache<SubstitutionScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SubstitutionScore? {
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

        func save(_ item: SubstitutionScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SubstitutionScore] {
            return inner.list()
        }
    }

    static func newCachedSubstitutionScoreStore(_ inner: MemorySubstitutionScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SubstitutionScoreStore {
        return CachedSubstitutionScoreStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects substitution scores. Empty fields match all.
    final class SubstitutionScoreQuery {
        var name: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SubstitutionScore) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SubstitutionScore]) -> [SubstitutionScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SubstitutionScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSubstitutionScores(_ store: any SubstitutionScoreStore, query: SubstitutionScoreQuery) -> [SubstitutionScore] {
        return query.apply(store.list())
    }
}
