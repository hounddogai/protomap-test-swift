import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps acuity plan thresholds by code.
    protocol AcuityPlanThresholdStore {
        func find(_ code: String) -> AcuityPlanThreshold?
        func save(_ item: AcuityPlanThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [AcuityPlanThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAcuityPlanThresholdStore: AcuityPlanThresholdStore {
        var items: [String: AcuityPlanThreshold]
        var order: [String]

        init(items: [String: AcuityPlanThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AcuityPlanThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AcuityPlanThreshold) {
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

        func list() -> [AcuityPlanThreshold] {
            var out: [AcuityPlanThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAcuityPlanThresholdStore() -> any AcuityPlanThresholdStore {
        return MemoryAcuityPlanThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAcuityPlanThresholdStore: AcuityPlanThresholdStore {
        var inner: MemoryAcuityPlanThresholdStore
        var cache: TTLCache<AcuityPlanThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryAcuityPlanThresholdStore, cache: TTLCache<AcuityPlanThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AcuityPlanThreshold? {
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

        func save(_ item: AcuityPlanThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AcuityPlanThreshold] {
            return inner.list()
        }
    }

    static func newCachedAcuityPlanThresholdStore(_ inner: MemoryAcuityPlanThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AcuityPlanThresholdStore {
        return CachedAcuityPlanThresholdStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects acuity plan thresholds. Empty fields match all.
    final class AcuityPlanThresholdQuery {
        var segment: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AcuityPlanThreshold) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AcuityPlanThreshold]) -> [AcuityPlanThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AcuityPlanThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAcuityPlanThresholds(_ store: any AcuityPlanThresholdStore, query: AcuityPlanThresholdQuery) -> [AcuityPlanThreshold] {
        return query.apply(store.list())
    }
}
