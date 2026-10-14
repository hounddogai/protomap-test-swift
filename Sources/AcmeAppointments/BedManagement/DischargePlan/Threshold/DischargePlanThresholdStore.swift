import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps discharge plan thresholds by code.
    protocol DischargePlanThresholdStore {
        func find(_ code: String) -> DischargePlanThreshold?
        func save(_ item: DischargePlanThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [DischargePlanThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDischargePlanThresholdStore: DischargePlanThresholdStore {
        var items: [String: DischargePlanThreshold]
        var order: [String]

        init(items: [String: DischargePlanThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DischargePlanThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DischargePlanThreshold) {
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

        func list() -> [DischargePlanThreshold] {
            var out: [DischargePlanThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDischargePlanThresholdStore() -> any DischargePlanThresholdStore {
        return MemoryDischargePlanThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDischargePlanThresholdStore: DischargePlanThresholdStore {
        var inner: MemoryDischargePlanThresholdStore
        var cache: TTLCache<DischargePlanThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryDischargePlanThresholdStore, cache: TTLCache<DischargePlanThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DischargePlanThreshold? {
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

        func save(_ item: DischargePlanThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DischargePlanThreshold] {
            return inner.list()
        }
    }

    static func newCachedDischargePlanThresholdStore(_ inner: MemoryDischargePlanThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DischargePlanThresholdStore {
        return CachedDischargePlanThresholdStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects discharge plan thresholds. Empty fields match all.
    final class DischargePlanThresholdQuery {
        var source: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minCost: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DischargePlanThreshold) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DischargePlanThreshold]) -> [DischargePlanThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DischargePlanThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDischargePlanThresholds(_ store: any DischargePlanThresholdStore, query: DischargePlanThresholdQuery) -> [DischargePlanThreshold] {
        return query.apply(store.list())
    }
}
