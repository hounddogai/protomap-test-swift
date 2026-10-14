import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps legacy alert slots by code.
    protocol LegacyAlertSlotStore {
        func find(_ code: String) -> LegacyAlertSlot?
        func save(_ item: LegacyAlertSlot)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyAlertSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyAlertSlotStore: LegacyAlertSlotStore {
        var items: [String: LegacyAlertSlot]
        var order: [String]

        init(items: [String: LegacyAlertSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyAlertSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyAlertSlot) {
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

        func list() -> [LegacyAlertSlot] {
            var out: [LegacyAlertSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyAlertSlotStore() -> any LegacyAlertSlotStore {
        return MemoryLegacyAlertSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyAlertSlotStore: LegacyAlertSlotStore {
        var inner: MemoryLegacyAlertSlotStore
        var cache: TTLCache<LegacyAlertSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyAlertSlotStore, cache: TTLCache<LegacyAlertSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyAlertSlot? {
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

        func save(_ item: LegacyAlertSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyAlertSlot] {
            return inner.list()
        }
    }

    static func newCachedLegacyAlertSlotStore(_ inner: MemoryLegacyAlertSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyAlertSlotStore {
        return CachedLegacyAlertSlotStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy alert slots. Empty fields match all.
    final class LegacyAlertSlotQuery {
        var channel: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyAlertSlot) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyAlertSlot]) -> [LegacyAlertSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyAlertSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyAlertSlots(_ store: any LegacyAlertSlotStore, query: LegacyAlertSlotQuery) -> [LegacyAlertSlot] {
        return query.apply(store.list())
    }
}
