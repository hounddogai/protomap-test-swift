import AcmePlatform
import Foundation

extension Labs {
    /// Keeps result slots by code.
    protocol ResultSlotStore {
        func find(_ code: String) -> ResultSlot?
        func save(_ item: ResultSlot)
        func remove(_ code: String) -> Bool
        func list() -> [ResultSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryResultSlotStore: ResultSlotStore {
        var items: [String: ResultSlot]
        var order: [String]

        init(items: [String: ResultSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ResultSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ResultSlot) {
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

        func list() -> [ResultSlot] {
            var out: [ResultSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryResultSlotStore() -> any ResultSlotStore {
        return MemoryResultSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedResultSlotStore: ResultSlotStore {
        var inner: MemoryResultSlotStore
        var cache: TTLCache<ResultSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryResultSlotStore, cache: TTLCache<ResultSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ResultSlot? {
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

        func save(_ item: ResultSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ResultSlot] {
            return inner.list()
        }
    }

    static func newCachedResultSlotStore(_ inner: MemoryResultSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ResultSlotStore {
        return CachedResultSlotStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects result slots. Empty fields match all.
    final class ResultSlotQuery {
        var label: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minVersion: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ResultSlot) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [ResultSlot]) -> [ResultSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ResultSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findResultSlots(_ store: any ResultSlotStore, query: ResultSlotQuery) -> [ResultSlot] {
        return query.apply(store.list())
    }
}
