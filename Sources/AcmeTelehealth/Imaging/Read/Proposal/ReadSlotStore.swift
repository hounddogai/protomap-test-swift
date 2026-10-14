import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps read slots by code.
    protocol ReadSlotStore {
        func find(_ code: String) -> ReadSlot?
        func save(_ item: ReadSlot)
        func remove(_ code: String) -> Bool
        func list() -> [ReadSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReadSlotStore: ReadSlotStore {
        var items: [String: ReadSlot]
        var order: [String]

        init(items: [String: ReadSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReadSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReadSlot) {
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

        func list() -> [ReadSlot] {
            var out: [ReadSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReadSlotStore() -> any ReadSlotStore {
        return MemoryReadSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReadSlotStore: ReadSlotStore {
        var inner: MemoryReadSlotStore
        var cache: TTLCache<ReadSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryReadSlotStore, cache: TTLCache<ReadSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReadSlot? {
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

        func save(_ item: ReadSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReadSlot] {
            return inner.list()
        }
    }

    static func newCachedReadSlotStore(_ inner: MemoryReadSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReadSlotStore {
        return CachedReadSlotStore(inner: inner, cache: newTTLCache(64, ttl: ttl, clock: clock), hits: 0, misses: 0)
    }

    /// Selects read slots. Empty fields match all.
    final class ReadSlotQuery {
        var label: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReadSlot) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReadSlot]) -> [ReadSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReadSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReadSlots(_ store: any ReadSlotStore, query: ReadSlotQuery) -> [ReadSlot] {
        return query.apply(store.list())
    }
}
