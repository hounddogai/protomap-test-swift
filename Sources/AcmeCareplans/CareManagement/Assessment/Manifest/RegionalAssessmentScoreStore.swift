import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps regional assessment scores by code.
    protocol RegionalAssessmentScoreStore {
        func find(_ code: String) -> RegionalAssessmentScore?
        func save(_ item: RegionalAssessmentScore)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalAssessmentScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalAssessmentScoreStore: RegionalAssessmentScoreStore {
        var items: [String: RegionalAssessmentScore]
        var order: [String]

        init(items: [String: RegionalAssessmentScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalAssessmentScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalAssessmentScore) {
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

        func list() -> [RegionalAssessmentScore] {
            var out: [RegionalAssessmentScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalAssessmentScoreStore() -> any RegionalAssessmentScoreStore {
        return MemoryRegionalAssessmentScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalAssessmentScoreStore: RegionalAssessmentScoreStore {
        var inner: MemoryRegionalAssessmentScoreStore
        var cache: TTLCache<RegionalAssessmentScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalAssessmentScoreStore, cache: TTLCache<RegionalAssessmentScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalAssessmentScore? {
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

        func save(_ item: RegionalAssessmentScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalAssessmentScore] {
            return inner.list()
        }
    }

    static func newCachedRegionalAssessmentScoreStore(_ inner: MemoryRegionalAssessmentScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalAssessmentScoreStore {
        return CachedRegionalAssessmentScoreStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional assessment scores. Empty fields match all.
    final class RegionalAssessmentScoreQuery {
        var segment: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalAssessmentScore) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalAssessmentScore]) -> [RegionalAssessmentScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalAssessmentScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalAssessmentScores(_ store: any RegionalAssessmentScoreStore, query: RegionalAssessmentScoreQuery) -> [RegionalAssessmentScore] {
        return query.apply(store.list())
    }
}
