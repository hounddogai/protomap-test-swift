import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps assessment scores by code.
    protocol AssessmentScoreStore {
        func find(_ code: String) -> AssessmentScore?
        func save(_ item: AssessmentScore)
        func remove(_ code: String) -> Bool
        func list() -> [AssessmentScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAssessmentScoreStore: AssessmentScoreStore {
        var items: [String: AssessmentScore]
        var order: [String]

        init(items: [String: AssessmentScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AssessmentScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AssessmentScore) {
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

        func list() -> [AssessmentScore] {
            var out: [AssessmentScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAssessmentScoreStore() -> any AssessmentScoreStore {
        return MemoryAssessmentScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAssessmentScoreStore: AssessmentScoreStore {
        var inner: MemoryAssessmentScoreStore
        var cache: TTLCache<AssessmentScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryAssessmentScoreStore, cache: TTLCache<AssessmentScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AssessmentScore? {
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

        func save(_ item: AssessmentScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AssessmentScore] {
            return inner.list()
        }
    }

    static func newCachedAssessmentScoreStore(_ inner: MemoryAssessmentScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AssessmentScoreStore {
        return CachedAssessmentScoreStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects assessment scores. Empty fields match all.
    final class AssessmentScoreQuery {
        var title: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minRetries: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AssessmentScore) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AssessmentScore]) -> [AssessmentScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AssessmentScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAssessmentScores(_ store: any AssessmentScoreStore, query: AssessmentScoreQuery) -> [AssessmentScore] {
        return query.apply(store.list())
    }
}
