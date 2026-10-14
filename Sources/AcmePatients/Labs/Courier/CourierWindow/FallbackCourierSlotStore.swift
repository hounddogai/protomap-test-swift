import AcmePlatform
import Foundation

extension Labs {
    /// Keeps fallback courier slots by code.
    protocol FallbackCourierSlotStore {
        func find(_ code: String) -> FallbackCourierSlot?
        func save(_ item: FallbackCourierSlot)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackCourierSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackCourierSlotStore: FallbackCourierSlotStore {
        var items: [String: FallbackCourierSlot]
        var order: [String]

        init(items: [String: FallbackCourierSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackCourierSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackCourierSlot) {
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

        func list() -> [FallbackCourierSlot] {
            var out: [FallbackCourierSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackCourierSlotStore() -> any FallbackCourierSlotStore {
        return MemoryFallbackCourierSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackCourierSlotStore: FallbackCourierSlotStore {
        var inner: MemoryFallbackCourierSlotStore
        var cache: TTLCache<FallbackCourierSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackCourierSlotStore, cache: TTLCache<FallbackCourierSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackCourierSlot? {
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

        func save(_ item: FallbackCourierSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackCourierSlot] {
            return inner.list()
        }
    }

    static func newCachedFallbackCourierSlotStore(_ inner: MemoryFallbackCourierSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackCourierSlotStore {
        return CachedFallbackCourierSlotStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback courier slots. Empty fields match all.
    final class FallbackCourierSlotQuery {
        var name: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackCourierSlot) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackCourierSlot]) -> [FallbackCourierSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackCourierSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackCourierSlots(_ store: any FallbackCourierSlotStore, query: FallbackCourierSlotQuery) -> [FallbackCourierSlot] {
        return query.apply(store.list())
    }
}
