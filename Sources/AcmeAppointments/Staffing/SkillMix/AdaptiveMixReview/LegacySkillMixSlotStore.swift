import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps legacy skill mix slots by code.
    protocol LegacySkillMixSlotStore {
        func find(_ code: String) -> LegacySkillMixSlot?
        func save(_ item: LegacySkillMixSlot)
        func remove(_ code: String) -> Bool
        func list() -> [LegacySkillMixSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacySkillMixSlotStore: LegacySkillMixSlotStore {
        var items: [String: LegacySkillMixSlot]
        var order: [String]

        init(items: [String: LegacySkillMixSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacySkillMixSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacySkillMixSlot) {
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

        func list() -> [LegacySkillMixSlot] {
            var out: [LegacySkillMixSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacySkillMixSlotStore() -> any LegacySkillMixSlotStore {
        return MemoryLegacySkillMixSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacySkillMixSlotStore: LegacySkillMixSlotStore {
        var inner: MemoryLegacySkillMixSlotStore
        var cache: TTLCache<LegacySkillMixSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacySkillMixSlotStore, cache: TTLCache<LegacySkillMixSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacySkillMixSlot? {
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

        func save(_ item: LegacySkillMixSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacySkillMixSlot] {
            return inner.list()
        }
    }

    static func newCachedLegacySkillMixSlotStore(_ inner: MemoryLegacySkillMixSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacySkillMixSlotStore {
        return CachedLegacySkillMixSlotStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy skill mix slots. Empty fields match all.
    final class LegacySkillMixSlotQuery {
        var country: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacySkillMixSlot) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacySkillMixSlot]) -> [LegacySkillMixSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacySkillMixSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacySkillMixSlots(_ store: any LegacySkillMixSlotStore, query: LegacySkillMixSlotQuery) -> [LegacySkillMixSlot] {
        return query.apply(store.list())
    }
}
