import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps legacy closure cycles by code.
    protocol LegacyClosureCycleStore {
        func find(_ code: String) -> LegacyClosureCycle?
        func save(_ item: LegacyClosureCycle)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyClosureCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyClosureCycleStore: LegacyClosureCycleStore {
        var items: [String: LegacyClosureCycle]
        var order: [String]

        init(items: [String: LegacyClosureCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyClosureCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyClosureCycle) {
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

        func list() -> [LegacyClosureCycle] {
            var out: [LegacyClosureCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyClosureCycleStore() -> any LegacyClosureCycleStore {
        return MemoryLegacyClosureCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyClosureCycleStore: LegacyClosureCycleStore {
        var inner: MemoryLegacyClosureCycleStore
        var cache: TTLCache<LegacyClosureCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyClosureCycleStore, cache: TTLCache<LegacyClosureCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyClosureCycle? {
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

        func save(_ item: LegacyClosureCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyClosureCycle] {
            return inner.list()
        }
    }

    static func newCachedLegacyClosureCycleStore(_ inner: MemoryLegacyClosureCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyClosureCycleStore {
        return CachedLegacyClosureCycleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy closure cycles. Empty fields match all.
    final class LegacyClosureCycleQuery {
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

        func matches(_ item: LegacyClosureCycle) -> Bool {
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

        func apply(_ items: [LegacyClosureCycle]) -> [LegacyClosureCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyClosureCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyClosureCycles(_ store: any LegacyClosureCycleStore, query: LegacyClosureCycleQuery) -> [LegacyClosureCycle] {
        return query.apply(store.list())
    }
}
