import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps regional eligibility slots by code.
    protocol RegionalEligibilitySlotStore {
        func find(_ code: String) -> RegionalEligibilitySlot?
        func save(_ item: RegionalEligibilitySlot)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalEligibilitySlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalEligibilitySlotStore: RegionalEligibilitySlotStore {
        var items: [String: RegionalEligibilitySlot]
        var order: [String]

        init(items: [String: RegionalEligibilitySlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalEligibilitySlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalEligibilitySlot) {
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

        func list() -> [RegionalEligibilitySlot] {
            var out: [RegionalEligibilitySlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalEligibilitySlotStore() -> any RegionalEligibilitySlotStore {
        return MemoryRegionalEligibilitySlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalEligibilitySlotStore: RegionalEligibilitySlotStore {
        var inner: MemoryRegionalEligibilitySlotStore
        var cache: TTLCache<RegionalEligibilitySlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalEligibilitySlotStore, cache: TTLCache<RegionalEligibilitySlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalEligibilitySlot? {
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

        func save(_ item: RegionalEligibilitySlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalEligibilitySlot] {
            return inner.list()
        }
    }

    static func newCachedRegionalEligibilitySlotStore(_ inner: MemoryRegionalEligibilitySlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalEligibilitySlotStore {
        return CachedRegionalEligibilitySlotStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional eligibility slots. Empty fields match all.
    final class RegionalEligibilitySlotQuery {
        var label: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMargin: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalEligibilitySlot) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalEligibilitySlot]) -> [RegionalEligibilitySlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalEligibilitySlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalEligibilitySlots(_ store: any RegionalEligibilitySlotStore, query: RegionalEligibilitySlotQuery) -> [RegionalEligibilitySlot] {
        return query.apply(store.list())
    }
}
