import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps handoff cycles by code.
    protocol HandoffCycleStore {
        func find(_ code: String) -> HandoffCycle?
        func save(_ item: HandoffCycle)
        func remove(_ code: String) -> Bool
        func list() -> [HandoffCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryHandoffCycleStore: HandoffCycleStore {
        var items: [String: HandoffCycle]
        var order: [String]

        init(items: [String: HandoffCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> HandoffCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: HandoffCycle) {
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

        func list() -> [HandoffCycle] {
            var out: [HandoffCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryHandoffCycleStore() -> any HandoffCycleStore {
        return MemoryHandoffCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedHandoffCycleStore: HandoffCycleStore {
        var inner: MemoryHandoffCycleStore
        var cache: TTLCache<HandoffCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryHandoffCycleStore, cache: TTLCache<HandoffCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> HandoffCycle? {
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

        func save(_ item: HandoffCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [HandoffCycle] {
            return inner.list()
        }
    }

    static func newCachedHandoffCycleStore(_ inner: MemoryHandoffCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any HandoffCycleStore {
        return CachedHandoffCycleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects handoff cycles. Empty fields match all.
    final class HandoffCycleQuery {
        var facility: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minAmount: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: HandoffCycle) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [HandoffCycle]) -> [HandoffCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: HandoffCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findHandoffCycles(_ store: any HandoffCycleStore, query: HandoffCycleQuery) -> [HandoffCycle] {
        return query.apply(store.list())
    }
}
