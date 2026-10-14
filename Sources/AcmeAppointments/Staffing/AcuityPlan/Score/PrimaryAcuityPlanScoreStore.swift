import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps primary acuity plan scores by code.
    protocol PrimaryAcuityPlanScoreStore {
        func find(_ code: String) -> PrimaryAcuityPlanScore?
        func save(_ item: PrimaryAcuityPlanScore)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryAcuityPlanScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryAcuityPlanScoreStore: PrimaryAcuityPlanScoreStore {
        var items: [String: PrimaryAcuityPlanScore]
        var order: [String]

        init(items: [String: PrimaryAcuityPlanScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryAcuityPlanScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryAcuityPlanScore) {
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

        func list() -> [PrimaryAcuityPlanScore] {
            var out: [PrimaryAcuityPlanScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryAcuityPlanScoreStore() -> any PrimaryAcuityPlanScoreStore {
        return MemoryPrimaryAcuityPlanScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryAcuityPlanScoreStore: PrimaryAcuityPlanScoreStore {
        var inner: MemoryPrimaryAcuityPlanScoreStore
        var cache: TTLCache<PrimaryAcuityPlanScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryAcuityPlanScoreStore, cache: TTLCache<PrimaryAcuityPlanScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryAcuityPlanScore? {
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

        func save(_ item: PrimaryAcuityPlanScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryAcuityPlanScore] {
            return inner.list()
        }
    }

    static func newCachedPrimaryAcuityPlanScoreStore(_ inner: MemoryPrimaryAcuityPlanScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryAcuityPlanScoreStore {
        return CachedPrimaryAcuityPlanScoreStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary acuity plan scores. Empty fields match all.
    final class PrimaryAcuityPlanScoreQuery {
        var title: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMargin: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryAcuityPlanScore) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryAcuityPlanScore]) -> [PrimaryAcuityPlanScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryAcuityPlanScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryAcuityPlanScores(_ store: any PrimaryAcuityPlanScoreStore, query: PrimaryAcuityPlanScoreQuery) -> [PrimaryAcuityPlanScore] {
        return query.apply(store.list())
    }
}
