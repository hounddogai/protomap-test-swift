import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps overtime targets by code.
    protocol OvertimeTargetStore {
        func find(_ code: String) -> OvertimeTarget?
        func save(_ item: OvertimeTarget)
        func remove(_ code: String) -> Bool
        func list() -> [OvertimeTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOvertimeTargetStore: OvertimeTargetStore {
        var items: [String: OvertimeTarget]
        var order: [String]

        init(items: [String: OvertimeTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OvertimeTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OvertimeTarget) {
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

        func list() -> [OvertimeTarget] {
            var out: [OvertimeTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOvertimeTargetStore() -> any OvertimeTargetStore {
        return MemoryOvertimeTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOvertimeTargetStore: OvertimeTargetStore {
        var inner: MemoryOvertimeTargetStore
        var cache: TTLCache<OvertimeTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryOvertimeTargetStore, cache: TTLCache<OvertimeTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OvertimeTarget? {
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

        func save(_ item: OvertimeTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OvertimeTarget] {
            return inner.list()
        }
    }

    static func newCachedOvertimeTargetStore(_ inner: MemoryOvertimeTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OvertimeTargetStore {
        return CachedOvertimeTargetStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects overtime targets. Empty fields match all.
    final class OvertimeTargetQuery {
        var unit: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OvertimeTarget) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OvertimeTarget]) -> [OvertimeTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OvertimeTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOvertimeTargets(_ store: any OvertimeTargetStore, query: OvertimeTargetQuery) -> [OvertimeTarget] {
        return query.apply(store.list())
    }
}
