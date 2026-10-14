import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps risk score milestones by code.
    protocol RiskScoreMilestoneStore {
        func find(_ code: String) -> RiskScoreMilestone?
        func save(_ item: RiskScoreMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [RiskScoreMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRiskScoreMilestoneStore: RiskScoreMilestoneStore {
        var items: [String: RiskScoreMilestone]
        var order: [String]

        init(items: [String: RiskScoreMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RiskScoreMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RiskScoreMilestone) {
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

        func list() -> [RiskScoreMilestone] {
            var out: [RiskScoreMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRiskScoreMilestoneStore() -> any RiskScoreMilestoneStore {
        return MemoryRiskScoreMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRiskScoreMilestoneStore: RiskScoreMilestoneStore {
        var inner: MemoryRiskScoreMilestoneStore
        var cache: TTLCache<RiskScoreMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryRiskScoreMilestoneStore, cache: TTLCache<RiskScoreMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RiskScoreMilestone? {
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

        func save(_ item: RiskScoreMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RiskScoreMilestone] {
            return inner.list()
        }
    }

    static func newCachedRiskScoreMilestoneStore(_ inner: MemoryRiskScoreMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RiskScoreMilestoneStore {
        return CachedRiskScoreMilestoneStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects risk score milestones. Empty fields match all.
    final class RiskScoreMilestoneQuery {
        var unit: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minMargin: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RiskScoreMilestone) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [RiskScoreMilestone]) -> [RiskScoreMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RiskScoreMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRiskScoreMilestones(_ store: any RiskScoreMilestoneStore, query: RiskScoreMilestoneQuery) -> [RiskScoreMilestone] {
        return query.apply(store.list())
    }
}
