import AcmePlatform
import Foundation

extension Labs {
    /// Keeps reference range slots by code.
    protocol ReferenceRangeSlotStore {
        func find(_ code: String) -> ReferenceRangeSlot?
        func save(_ item: ReferenceRangeSlot)
        func remove(_ code: String) -> Bool
        func list() -> [ReferenceRangeSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferenceRangeSlotStore: ReferenceRangeSlotStore {
        var items: [String: ReferenceRangeSlot]
        var order: [String]

        init(items: [String: ReferenceRangeSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferenceRangeSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferenceRangeSlot) {
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

        func list() -> [ReferenceRangeSlot] {
            var out: [ReferenceRangeSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferenceRangeSlotStore() -> any ReferenceRangeSlotStore {
        return MemoryReferenceRangeSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferenceRangeSlotStore: ReferenceRangeSlotStore {
        var inner: MemoryReferenceRangeSlotStore
        var cache: TTLCache<ReferenceRangeSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferenceRangeSlotStore, cache: TTLCache<ReferenceRangeSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferenceRangeSlot? {
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

        func save(_ item: ReferenceRangeSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferenceRangeSlot] {
            return inner.list()
        }
    }

    static func newCachedReferenceRangeSlotStore(_ inner: MemoryReferenceRangeSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferenceRangeSlotStore {
        return CachedReferenceRangeSlotStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects reference range slots. Empty fields match all.
    final class ReferenceRangeSlotQuery {
        var category: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minScore: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferenceRangeSlot) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [ReferenceRangeSlot]) -> [ReferenceRangeSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferenceRangeSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferenceRangeSlots(_ store: any ReferenceRangeSlotStore, query: ReferenceRangeSlotQuery) -> [ReferenceRangeSlot] {
        return query.apply(store.list())
    }
}
