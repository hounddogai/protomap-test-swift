import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps manual outreach slots by code.
    protocol ManualOutreachSlotStore {
        func find(_ code: String) -> ManualOutreachSlot?
        func save(_ item: ManualOutreachSlot)
        func remove(_ code: String) -> Bool
        func list() -> [ManualOutreachSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualOutreachSlotStore: ManualOutreachSlotStore {
        var items: [String: ManualOutreachSlot]
        var order: [String]

        init(items: [String: ManualOutreachSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualOutreachSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualOutreachSlot) {
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

        func list() -> [ManualOutreachSlot] {
            var out: [ManualOutreachSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualOutreachSlotStore() -> any ManualOutreachSlotStore {
        return MemoryManualOutreachSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualOutreachSlotStore: ManualOutreachSlotStore {
        var inner: MemoryManualOutreachSlotStore
        var cache: TTLCache<ManualOutreachSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualOutreachSlotStore, cache: TTLCache<ManualOutreachSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualOutreachSlot? {
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

        func save(_ item: ManualOutreachSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualOutreachSlot] {
            return inner.list()
        }
    }

    static func newCachedManualOutreachSlotStore(_ inner: MemoryManualOutreachSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualOutreachSlotStore {
        return CachedManualOutreachSlotStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual outreach slots. Empty fields match all.
    final class ManualOutreachSlotQuery {
        var ward: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minScore: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualOutreachSlot) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [ManualOutreachSlot]) -> [ManualOutreachSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualOutreachSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualOutreachSlots(_ store: any ManualOutreachSlotStore, query: ManualOutreachSlotQuery) -> [ManualOutreachSlot] {
        return query.apply(store.list())
    }
}
