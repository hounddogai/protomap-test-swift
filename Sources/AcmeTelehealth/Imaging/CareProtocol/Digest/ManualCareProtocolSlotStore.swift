import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps manual care protocol slots by code.
    protocol ManualCareProtocolSlotStore {
        func find(_ code: String) -> ManualCareProtocolSlot?
        func save(_ item: ManualCareProtocolSlot)
        func remove(_ code: String) -> Bool
        func list() -> [ManualCareProtocolSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualCareProtocolSlotStore: ManualCareProtocolSlotStore {
        var items: [String: ManualCareProtocolSlot]
        var order: [String]

        init(items: [String: ManualCareProtocolSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualCareProtocolSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualCareProtocolSlot) {
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

        func list() -> [ManualCareProtocolSlot] {
            var out: [ManualCareProtocolSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualCareProtocolSlotStore() -> any ManualCareProtocolSlotStore {
        return MemoryManualCareProtocolSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualCareProtocolSlotStore: ManualCareProtocolSlotStore {
        var inner: MemoryManualCareProtocolSlotStore
        var cache: TTLCache<ManualCareProtocolSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualCareProtocolSlotStore, cache: TTLCache<ManualCareProtocolSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualCareProtocolSlot? {
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

        func save(_ item: ManualCareProtocolSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualCareProtocolSlot] {
            return inner.list()
        }
    }

    static func newCachedManualCareProtocolSlotStore(_ inner: MemoryManualCareProtocolSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualCareProtocolSlotStore {
        return CachedManualCareProtocolSlotStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual care protocol slots. Empty fields match all.
    final class ManualCareProtocolSlotQuery {
        var label: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minScore: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualCareProtocolSlot) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [ManualCareProtocolSlot]) -> [ManualCareProtocolSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualCareProtocolSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualCareProtocolSlots(_ store: any ManualCareProtocolSlotStore, query: ManualCareProtocolSlotQuery) -> [ManualCareProtocolSlot] {
        return query.apply(store.list())
    }
}
