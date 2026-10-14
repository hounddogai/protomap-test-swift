import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps adaptive acuity plan scores by code.
    protocol AdaptiveAcuityPlanScoreStore {
        func find(_ code: String) -> AdaptiveAcuityPlanScore?
        func save(_ item: AdaptiveAcuityPlanScore)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveAcuityPlanScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveAcuityPlanScoreStore: AdaptiveAcuityPlanScoreStore {
        var items: [String: AdaptiveAcuityPlanScore]
        var order: [String]

        init(items: [String: AdaptiveAcuityPlanScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveAcuityPlanScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveAcuityPlanScore) {
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

        func list() -> [AdaptiveAcuityPlanScore] {
            var out: [AdaptiveAcuityPlanScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveAcuityPlanScoreStore() -> any AdaptiveAcuityPlanScoreStore {
        return MemoryAdaptiveAcuityPlanScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveAcuityPlanScoreStore: AdaptiveAcuityPlanScoreStore {
        var inner: MemoryAdaptiveAcuityPlanScoreStore
        var cache: TTLCache<AdaptiveAcuityPlanScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveAcuityPlanScoreStore, cache: TTLCache<AdaptiveAcuityPlanScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveAcuityPlanScore? {
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

        func save(_ item: AdaptiveAcuityPlanScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveAcuityPlanScore] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveAcuityPlanScoreStore(_ inner: MemoryAdaptiveAcuityPlanScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveAcuityPlanScoreStore {
        return CachedAdaptiveAcuityPlanScoreStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive acuity plan scores. Empty fields match all.
    final class AdaptiveAcuityPlanScoreQuery {
        var country: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minRetries: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveAcuityPlanScore) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [AdaptiveAcuityPlanScore]) -> [AdaptiveAcuityPlanScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveAcuityPlanScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveAcuityPlanScores(_ store: any AdaptiveAcuityPlanScoreStore, query: AdaptiveAcuityPlanScoreQuery) -> [AdaptiveAcuityPlanScore] {
        return query.apply(store.list())
    }
}
