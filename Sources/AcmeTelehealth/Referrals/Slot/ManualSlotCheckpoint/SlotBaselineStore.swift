import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps slot baselines by code.
    protocol SlotBaselineStore {
        func find(_ code: String) -> SlotBaseline?
        func save(_ item: SlotBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [SlotBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySlotBaselineStore: SlotBaselineStore {
        var items: [String: SlotBaseline]
        var order: [String]

        init(items: [String: SlotBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SlotBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SlotBaseline) {
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

        func list() -> [SlotBaseline] {
            var out: [SlotBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySlotBaselineStore() -> any SlotBaselineStore {
        return MemorySlotBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSlotBaselineStore: SlotBaselineStore {
        var inner: MemorySlotBaselineStore
        var cache: TTLCache<SlotBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemorySlotBaselineStore, cache: TTLCache<SlotBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SlotBaseline? {
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

        func save(_ item: SlotBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SlotBaseline] {
            return inner.list()
        }
    }

    static func newCachedSlotBaselineStore(_ inner: MemorySlotBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SlotBaselineStore {
        return CachedSlotBaselineStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects slot baselines. Empty fields match all.
    final class SlotBaselineQuery {
        var ward: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minCost: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SlotBaseline) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SlotBaseline]) -> [SlotBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SlotBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSlotBaselines(_ store: any SlotBaselineStore, query: SlotBaselineQuery) -> [SlotBaseline] {
        return query.apply(store.list())
    }
}
