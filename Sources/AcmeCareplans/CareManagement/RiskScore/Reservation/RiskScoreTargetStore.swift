import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps risk score targets by code.
    protocol RiskScoreTargetStore {
        func find(_ code: String) -> RiskScoreTarget?
        func save(_ item: RiskScoreTarget)
        func remove(_ code: String) -> Bool
        func list() -> [RiskScoreTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRiskScoreTargetStore: RiskScoreTargetStore {
        var items: [String: RiskScoreTarget]
        var order: [String]

        init(items: [String: RiskScoreTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RiskScoreTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RiskScoreTarget) {
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

        func list() -> [RiskScoreTarget] {
            var out: [RiskScoreTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRiskScoreTargetStore() -> any RiskScoreTargetStore {
        return MemoryRiskScoreTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRiskScoreTargetStore: RiskScoreTargetStore {
        var inner: MemoryRiskScoreTargetStore
        var cache: TTLCache<RiskScoreTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryRiskScoreTargetStore, cache: TTLCache<RiskScoreTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RiskScoreTarget? {
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

        func save(_ item: RiskScoreTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RiskScoreTarget] {
            return inner.list()
        }
    }

    static func newCachedRiskScoreTargetStore(_ inner: MemoryRiskScoreTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RiskScoreTargetStore {
        return CachedRiskScoreTargetStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects risk score targets. Empty fields match all.
    final class RiskScoreTargetQuery {
        var label: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RiskScoreTarget) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RiskScoreTarget]) -> [RiskScoreTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RiskScoreTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRiskScoreTargets(_ store: any RiskScoreTargetStore, query: RiskScoreTargetQuery) -> [RiskScoreTarget] {
        return query.apply(store.list())
    }
}
