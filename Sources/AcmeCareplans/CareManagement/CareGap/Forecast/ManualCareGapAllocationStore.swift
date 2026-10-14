import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps manual care gap allocations by code.
    protocol ManualCareGapAllocationStore {
        func find(_ code: String) -> ManualCareGapAllocation?
        func save(_ item: ManualCareGapAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [ManualCareGapAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualCareGapAllocationStore: ManualCareGapAllocationStore {
        var items: [String: ManualCareGapAllocation]
        var order: [String]

        init(items: [String: ManualCareGapAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualCareGapAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualCareGapAllocation) {
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

        func list() -> [ManualCareGapAllocation] {
            var out: [ManualCareGapAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualCareGapAllocationStore() -> any ManualCareGapAllocationStore {
        return MemoryManualCareGapAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualCareGapAllocationStore: ManualCareGapAllocationStore {
        var inner: MemoryManualCareGapAllocationStore
        var cache: TTLCache<ManualCareGapAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualCareGapAllocationStore, cache: TTLCache<ManualCareGapAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualCareGapAllocation? {
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

        func save(_ item: ManualCareGapAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualCareGapAllocation] {
            return inner.list()
        }
    }

    static func newCachedManualCareGapAllocationStore(_ inner: MemoryManualCareGapAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualCareGapAllocationStore {
        return CachedManualCareGapAllocationStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual care gap allocations. Empty fields match all.
    final class ManualCareGapAllocationQuery {
        var country: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minCopay: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualCareGapAllocation) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualCareGapAllocation]) -> [ManualCareGapAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualCareGapAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualCareGapAllocations(_ store: any ManualCareGapAllocationStore, query: ManualCareGapAllocationQuery) -> [ManualCareGapAllocation] {
        return query.apply(store.list())
    }
}
