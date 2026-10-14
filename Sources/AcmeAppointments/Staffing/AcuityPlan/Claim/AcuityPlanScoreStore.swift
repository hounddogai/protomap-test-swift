import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps acuity plan scores by code.
    protocol AcuityPlanScoreStore {
        func find(_ code: String) -> AcuityPlanScore?
        func save(_ item: AcuityPlanScore)
        func remove(_ code: String) -> Bool
        func list() -> [AcuityPlanScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAcuityPlanScoreStore: AcuityPlanScoreStore {
        var items: [String: AcuityPlanScore]
        var order: [String]

        init(items: [String: AcuityPlanScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AcuityPlanScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AcuityPlanScore) {
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

        func list() -> [AcuityPlanScore] {
            var out: [AcuityPlanScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAcuityPlanScoreStore() -> any AcuityPlanScoreStore {
        return MemoryAcuityPlanScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAcuityPlanScoreStore: AcuityPlanScoreStore {
        var inner: MemoryAcuityPlanScoreStore
        var cache: TTLCache<AcuityPlanScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryAcuityPlanScoreStore, cache: TTLCache<AcuityPlanScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AcuityPlanScore? {
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

        func save(_ item: AcuityPlanScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AcuityPlanScore] {
            return inner.list()
        }
    }

    static func newCachedAcuityPlanScoreStore(_ inner: MemoryAcuityPlanScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AcuityPlanScoreStore {
        return CachedAcuityPlanScoreStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects acuity plan scores. Empty fields match all.
    final class AcuityPlanScoreQuery {
        var unit: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minAmount: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AcuityPlanScore) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AcuityPlanScore]) -> [AcuityPlanScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AcuityPlanScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAcuityPlanScores(_ store: any AcuityPlanScoreStore, query: AcuityPlanScoreQuery) -> [AcuityPlanScore] {
        return query.apply(store.list())
    }
}
