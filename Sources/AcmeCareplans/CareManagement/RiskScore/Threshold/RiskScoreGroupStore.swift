import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps risk score groups by code.
    protocol RiskScoreGroupStore {
        func find(_ code: String) -> RiskScoreGroup?
        func save(_ item: RiskScoreGroup)
        func remove(_ code: String) -> Bool
        func list() -> [RiskScoreGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRiskScoreGroupStore: RiskScoreGroupStore {
        var items: [String: RiskScoreGroup]
        var order: [String]

        init(items: [String: RiskScoreGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RiskScoreGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RiskScoreGroup) {
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

        func list() -> [RiskScoreGroup] {
            var out: [RiskScoreGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRiskScoreGroupStore() -> any RiskScoreGroupStore {
        return MemoryRiskScoreGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRiskScoreGroupStore: RiskScoreGroupStore {
        var inner: MemoryRiskScoreGroupStore
        var cache: TTLCache<RiskScoreGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryRiskScoreGroupStore, cache: TTLCache<RiskScoreGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RiskScoreGroup? {
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

        func save(_ item: RiskScoreGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RiskScoreGroup] {
            return inner.list()
        }
    }

    static func newCachedRiskScoreGroupStore(_ inner: MemoryRiskScoreGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RiskScoreGroupStore {
        return CachedRiskScoreGroupStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects risk score groups. Empty fields match all.
    final class RiskScoreGroupQuery {
        var unit: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RiskScoreGroup) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RiskScoreGroup]) -> [RiskScoreGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RiskScoreGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRiskScoreGroups(_ store: any RiskScoreGroupStore, query: RiskScoreGroupQuery) -> [RiskScoreGroup] {
        return query.apply(store.list())
    }
}
