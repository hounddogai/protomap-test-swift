import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps shift mappings by code.
    protocol ShiftMappingStore {
        func find(_ code: String) -> ShiftMapping?
        func save(_ item: ShiftMapping)
        func remove(_ code: String) -> Bool
        func list() -> [ShiftMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryShiftMappingStore: ShiftMappingStore {
        var items: [String: ShiftMapping]
        var order: [String]

        init(items: [String: ShiftMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ShiftMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ShiftMapping) {
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

        func list() -> [ShiftMapping] {
            var out: [ShiftMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryShiftMappingStore() -> any ShiftMappingStore {
        return MemoryShiftMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedShiftMappingStore: ShiftMappingStore {
        var inner: MemoryShiftMappingStore
        var cache: TTLCache<ShiftMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryShiftMappingStore, cache: TTLCache<ShiftMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ShiftMapping? {
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

        func save(_ item: ShiftMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ShiftMapping] {
            return inner.list()
        }
    }

    static func newCachedShiftMappingStore(_ inner: MemoryShiftMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ShiftMappingStore {
        return CachedShiftMappingStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects shift mappings. Empty fields match all.
    final class ShiftMappingQuery {
        var name: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRefills: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ShiftMapping) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ShiftMapping]) -> [ShiftMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ShiftMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findShiftMappings(_ store: any ShiftMappingStore, query: ShiftMappingQuery) -> [ShiftMapping] {
        return query.apply(store.list())
    }
}
