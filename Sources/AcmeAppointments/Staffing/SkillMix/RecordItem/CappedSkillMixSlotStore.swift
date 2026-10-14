import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps capped skill mix slots by code.
    protocol CappedSkillMixSlotStore {
        func find(_ code: String) -> CappedSkillMixSlot?
        func save(_ item: CappedSkillMixSlot)
        func remove(_ code: String) -> Bool
        func list() -> [CappedSkillMixSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedSkillMixSlotStore: CappedSkillMixSlotStore {
        var items: [String: CappedSkillMixSlot]
        var order: [String]

        init(items: [String: CappedSkillMixSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedSkillMixSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedSkillMixSlot) {
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

        func list() -> [CappedSkillMixSlot] {
            var out: [CappedSkillMixSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedSkillMixSlotStore() -> any CappedSkillMixSlotStore {
        return MemoryCappedSkillMixSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedSkillMixSlotStore: CappedSkillMixSlotStore {
        var inner: MemoryCappedSkillMixSlotStore
        var cache: TTLCache<CappedSkillMixSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedSkillMixSlotStore, cache: TTLCache<CappedSkillMixSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedSkillMixSlot? {
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

        func save(_ item: CappedSkillMixSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedSkillMixSlot] {
            return inner.list()
        }
    }

    static func newCachedCappedSkillMixSlotStore(_ inner: MemoryCappedSkillMixSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedSkillMixSlotStore {
        return CachedCappedSkillMixSlotStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped skill mix slots. Empty fields match all.
    final class CappedSkillMixSlotQuery {
        var unit: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minWeight: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedSkillMixSlot) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedSkillMixSlot]) -> [CappedSkillMixSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedSkillMixSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedSkillMixSlots(_ store: any CappedSkillMixSlotStore, query: CappedSkillMixSlotQuery) -> [CappedSkillMixSlot] {
        return query.apply(store.list())
    }
}
