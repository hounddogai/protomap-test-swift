import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps shift windows by code.
    protocol ShiftWindowStore {
        func find(_ code: String) -> ShiftWindow?
        func save(_ item: ShiftWindow)
        func remove(_ code: String) -> Bool
        func list() -> [ShiftWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryShiftWindowStore: ShiftWindowStore {
        var items: [String: ShiftWindow]
        var order: [String]

        init(items: [String: ShiftWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ShiftWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ShiftWindow) {
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

        func list() -> [ShiftWindow] {
            var out: [ShiftWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryShiftWindowStore() -> any ShiftWindowStore {
        return MemoryShiftWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedShiftWindowStore: ShiftWindowStore {
        var inner: MemoryShiftWindowStore
        var cache: TTLCache<ShiftWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryShiftWindowStore, cache: TTLCache<ShiftWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ShiftWindow? {
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

        func save(_ item: ShiftWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ShiftWindow] {
            return inner.list()
        }
    }

    static func newCachedShiftWindowStore(_ inner: MemoryShiftWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ShiftWindowStore {
        return CachedShiftWindowStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects shift windows. Empty fields match all.
    final class ShiftWindowQuery {
        var unit: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minVersion: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ShiftWindow) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ShiftWindow]) -> [ShiftWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ShiftWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findShiftWindows(_ store: any ShiftWindowStore, query: ShiftWindowQuery) -> [ShiftWindow] {
        return query.apply(store.list())
    }
}
