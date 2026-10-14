import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps default acuity plan thresholds by code.
    protocol DefaultAcuityPlanThresholdStore {
        func find(_ code: String) -> DefaultAcuityPlanThreshold?
        func save(_ item: DefaultAcuityPlanThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultAcuityPlanThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultAcuityPlanThresholdStore: DefaultAcuityPlanThresholdStore {
        var items: [String: DefaultAcuityPlanThreshold]
        var order: [String]

        init(items: [String: DefaultAcuityPlanThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultAcuityPlanThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultAcuityPlanThreshold) {
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

        func list() -> [DefaultAcuityPlanThreshold] {
            var out: [DefaultAcuityPlanThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultAcuityPlanThresholdStore() -> any DefaultAcuityPlanThresholdStore {
        return MemoryDefaultAcuityPlanThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultAcuityPlanThresholdStore: DefaultAcuityPlanThresholdStore {
        var inner: MemoryDefaultAcuityPlanThresholdStore
        var cache: TTLCache<DefaultAcuityPlanThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultAcuityPlanThresholdStore, cache: TTLCache<DefaultAcuityPlanThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultAcuityPlanThreshold? {
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

        func save(_ item: DefaultAcuityPlanThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultAcuityPlanThreshold] {
            return inner.list()
        }
    }

    static func newCachedDefaultAcuityPlanThresholdStore(_ inner: MemoryDefaultAcuityPlanThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultAcuityPlanThresholdStore {
        return CachedDefaultAcuityPlanThresholdStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default acuity plan thresholds. Empty fields match all.
    final class DefaultAcuityPlanThresholdQuery {
        var label: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minScore: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultAcuityPlanThreshold) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultAcuityPlanThreshold]) -> [DefaultAcuityPlanThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultAcuityPlanThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultAcuityPlanThresholds(_ store: any DefaultAcuityPlanThresholdStore, query: DefaultAcuityPlanThresholdQuery) -> [DefaultAcuityPlanThreshold] {
        return query.apply(store.list())
    }
}
