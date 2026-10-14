import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps shift cycles by code.
    protocol ShiftCycleStore {
        func find(_ code: String) -> ShiftCycle?
        func save(_ item: ShiftCycle)
        func remove(_ code: String) -> Bool
        func list() -> [ShiftCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryShiftCycleStore: ShiftCycleStore {
        var items: [String: ShiftCycle]
        var order: [String]

        init(items: [String: ShiftCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ShiftCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ShiftCycle) {
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

        func list() -> [ShiftCycle] {
            var out: [ShiftCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryShiftCycleStore() -> any ShiftCycleStore {
        return MemoryShiftCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedShiftCycleStore: ShiftCycleStore {
        var inner: MemoryShiftCycleStore
        var cache: TTLCache<ShiftCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryShiftCycleStore, cache: TTLCache<ShiftCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ShiftCycle? {
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

        func save(_ item: ShiftCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ShiftCycle] {
            return inner.list()
        }
    }

    static func newCachedShiftCycleStore(_ inner: MemoryShiftCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ShiftCycleStore {
        return CachedShiftCycleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects shift cycles. Empty fields match all.
    final class ShiftCycleQuery {
        var name: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minCopay: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ShiftCycle) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ShiftCycle]) -> [ShiftCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ShiftCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findShiftCycles(_ store: any ShiftCycleStore, query: ShiftCycleQuery) -> [ShiftCycle] {
        return query.apply(store.list())
    }
}
