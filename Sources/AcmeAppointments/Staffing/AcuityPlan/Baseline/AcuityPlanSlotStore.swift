import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps acuity plan slots by code.
    protocol AcuityPlanSlotStore {
        func find(_ code: String) -> AcuityPlanSlot?
        func save(_ item: AcuityPlanSlot)
        func remove(_ code: String) -> Bool
        func list() -> [AcuityPlanSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAcuityPlanSlotStore: AcuityPlanSlotStore {
        var items: [String: AcuityPlanSlot]
        var order: [String]

        init(items: [String: AcuityPlanSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AcuityPlanSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AcuityPlanSlot) {
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

        func list() -> [AcuityPlanSlot] {
            var out: [AcuityPlanSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAcuityPlanSlotStore() -> any AcuityPlanSlotStore {
        return MemoryAcuityPlanSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAcuityPlanSlotStore: AcuityPlanSlotStore {
        var inner: MemoryAcuityPlanSlotStore
        var cache: TTLCache<AcuityPlanSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryAcuityPlanSlotStore, cache: TTLCache<AcuityPlanSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AcuityPlanSlot? {
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

        func save(_ item: AcuityPlanSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AcuityPlanSlot] {
            return inner.list()
        }
    }

    static func newCachedAcuityPlanSlotStore(_ inner: MemoryAcuityPlanSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AcuityPlanSlotStore {
        return CachedAcuityPlanSlotStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects acuity plan slots. Empty fields match all.
    final class AcuityPlanSlotQuery {
        var label: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minWeight: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AcuityPlanSlot) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [AcuityPlanSlot]) -> [AcuityPlanSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AcuityPlanSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAcuityPlanSlots(_ store: any AcuityPlanSlotStore, query: AcuityPlanSlotQuery) -> [AcuityPlanSlot] {
        return query.apply(store.list())
    }
}
