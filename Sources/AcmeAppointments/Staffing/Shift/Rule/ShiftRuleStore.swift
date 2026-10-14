import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps shift rules by code.
    protocol ShiftRuleStore {
        func find(_ code: String) -> ShiftRule?
        func save(_ item: ShiftRule)
        func remove(_ code: String) -> Bool
        func list() -> [ShiftRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryShiftRuleStore: ShiftRuleStore {
        var items: [String: ShiftRule]
        var order: [String]

        init(items: [String: ShiftRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ShiftRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ShiftRule) {
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

        func list() -> [ShiftRule] {
            var out: [ShiftRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryShiftRuleStore() -> any ShiftRuleStore {
        return MemoryShiftRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedShiftRuleStore: ShiftRuleStore {
        var inner: MemoryShiftRuleStore
        var cache: TTLCache<ShiftRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryShiftRuleStore, cache: TTLCache<ShiftRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ShiftRule? {
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

        func save(_ item: ShiftRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ShiftRule] {
            return inner.list()
        }
    }

    static func newCachedShiftRuleStore(_ inner: MemoryShiftRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ShiftRuleStore {
        return CachedShiftRuleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects shift rules. Empty fields match all.
    final class ShiftRuleQuery {
        var ward: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ShiftRule) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [ShiftRule]) -> [ShiftRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ShiftRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findShiftRules(_ store: any ShiftRuleStore, query: ShiftRuleQuery) -> [ShiftRule] {
        return query.apply(store.list())
    }
}
