import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps lenient assessment scores by code.
    protocol LenientAssessmentScoreStore {
        func find(_ code: String) -> LenientAssessmentScore?
        func save(_ item: LenientAssessmentScore)
        func remove(_ code: String) -> Bool
        func list() -> [LenientAssessmentScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientAssessmentScoreStore: LenientAssessmentScoreStore {
        var items: [String: LenientAssessmentScore]
        var order: [String]

        init(items: [String: LenientAssessmentScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientAssessmentScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientAssessmentScore) {
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

        func list() -> [LenientAssessmentScore] {
            var out: [LenientAssessmentScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientAssessmentScoreStore() -> any LenientAssessmentScoreStore {
        return MemoryLenientAssessmentScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientAssessmentScoreStore: LenientAssessmentScoreStore {
        var inner: MemoryLenientAssessmentScoreStore
        var cache: TTLCache<LenientAssessmentScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientAssessmentScoreStore, cache: TTLCache<LenientAssessmentScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientAssessmentScore? {
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

        func save(_ item: LenientAssessmentScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientAssessmentScore] {
            return inner.list()
        }
    }

    static func newCachedLenientAssessmentScoreStore(_ inner: MemoryLenientAssessmentScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientAssessmentScoreStore {
        return CachedLenientAssessmentScoreStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient assessment scores. Empty fields match all.
    final class LenientAssessmentScoreQuery {
        var name: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minSequence: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientAssessmentScore) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientAssessmentScore]) -> [LenientAssessmentScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientAssessmentScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientAssessmentScores(_ store: any LenientAssessmentScoreStore, query: LenientAssessmentScoreQuery) -> [LenientAssessmentScore] {
        return query.apply(store.list())
    }
}
