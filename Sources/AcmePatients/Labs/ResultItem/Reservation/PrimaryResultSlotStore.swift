import AcmePlatform
import Foundation

extension Labs {
    /// Keeps primary result slots by code.
    protocol PrimaryResultSlotStore {
        func find(_ code: String) -> PrimaryResultSlot?
        func save(_ item: PrimaryResultSlot)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryResultSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryResultSlotStore: PrimaryResultSlotStore {
        var items: [String: PrimaryResultSlot]
        var order: [String]

        init(items: [String: PrimaryResultSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryResultSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryResultSlot) {
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

        func list() -> [PrimaryResultSlot] {
            var out: [PrimaryResultSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryResultSlotStore() -> any PrimaryResultSlotStore {
        return MemoryPrimaryResultSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryResultSlotStore: PrimaryResultSlotStore {
        var inner: MemoryPrimaryResultSlotStore
        var cache: TTLCache<PrimaryResultSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryResultSlotStore, cache: TTLCache<PrimaryResultSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryResultSlot? {
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

        func save(_ item: PrimaryResultSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryResultSlot] {
            return inner.list()
        }
    }

    static func newCachedPrimaryResultSlotStore(_ inner: MemoryPrimaryResultSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryResultSlotStore {
        return CachedPrimaryResultSlotStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary result slots. Empty fields match all.
    final class PrimaryResultSlotQuery {
        var title: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minScore: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryResultSlot) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryResultSlot]) -> [PrimaryResultSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryResultSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryResultSlots(_ store: any PrimaryResultSlotStore, query: PrimaryResultSlotQuery) -> [PrimaryResultSlot] {
        return query.apply(store.list())
    }
}
