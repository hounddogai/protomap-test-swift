import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps strict shift thresholds by code.
    protocol StrictShiftThresholdStore {
        func find(_ code: String) -> StrictShiftThreshold?
        func save(_ item: StrictShiftThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [StrictShiftThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictShiftThresholdStore: StrictShiftThresholdStore {
        var items: [String: StrictShiftThreshold]
        var order: [String]

        init(items: [String: StrictShiftThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictShiftThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictShiftThreshold) {
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

        func list() -> [StrictShiftThreshold] {
            var out: [StrictShiftThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictShiftThresholdStore() -> any StrictShiftThresholdStore {
        return MemoryStrictShiftThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictShiftThresholdStore: StrictShiftThresholdStore {
        var inner: MemoryStrictShiftThresholdStore
        var cache: TTLCache<StrictShiftThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictShiftThresholdStore, cache: TTLCache<StrictShiftThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictShiftThreshold? {
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

        func save(_ item: StrictShiftThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictShiftThreshold] {
            return inner.list()
        }
    }

    static func newCachedStrictShiftThresholdStore(_ inner: MemoryStrictShiftThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictShiftThresholdStore {
        return CachedStrictShiftThresholdStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict shift thresholds. Empty fields match all.
    final class StrictShiftThresholdQuery {
        var ward: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictShiftThreshold) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictShiftThreshold]) -> [StrictShiftThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictShiftThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictShiftThresholds(_ store: any StrictShiftThresholdStore, query: StrictShiftThresholdQuery) -> [StrictShiftThreshold] {
        return query.apply(store.list())
    }
}
