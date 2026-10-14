import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps care gap cycles by code.
    protocol CareGapCycleStore {
        func find(_ code: String) -> CareGapCycle?
        func save(_ item: CareGapCycle)
        func remove(_ code: String) -> Bool
        func list() -> [CareGapCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareGapCycleStore: CareGapCycleStore {
        var items: [String: CareGapCycle]
        var order: [String]

        init(items: [String: CareGapCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareGapCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareGapCycle) {
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

        func list() -> [CareGapCycle] {
            var out: [CareGapCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareGapCycleStore() -> any CareGapCycleStore {
        return MemoryCareGapCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareGapCycleStore: CareGapCycleStore {
        var inner: MemoryCareGapCycleStore
        var cache: TTLCache<CareGapCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareGapCycleStore, cache: TTLCache<CareGapCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareGapCycle? {
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

        func save(_ item: CareGapCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareGapCycle] {
            return inner.list()
        }
    }

    static func newCachedCareGapCycleStore(_ inner: MemoryCareGapCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareGapCycleStore {
        return CachedCareGapCycleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care gap cycles. Empty fields match all.
    final class CareGapCycleQuery {
        var title: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareGapCycle) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [CareGapCycle]) -> [CareGapCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareGapCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareGapCycles(_ store: any CareGapCycleStore, query: CareGapCycleQuery) -> [CareGapCycle] {
        return query.apply(store.list())
    }
}
