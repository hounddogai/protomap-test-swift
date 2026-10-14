import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps adaptive assessment allocations by code.
    protocol AdaptiveAssessmentAllocationStore {
        func find(_ code: String) -> AdaptiveAssessmentAllocation?
        func save(_ item: AdaptiveAssessmentAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveAssessmentAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveAssessmentAllocationStore: AdaptiveAssessmentAllocationStore {
        var items: [String: AdaptiveAssessmentAllocation]
        var order: [String]

        init(items: [String: AdaptiveAssessmentAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveAssessmentAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveAssessmentAllocation) {
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

        func list() -> [AdaptiveAssessmentAllocation] {
            var out: [AdaptiveAssessmentAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveAssessmentAllocationStore() -> any AdaptiveAssessmentAllocationStore {
        return MemoryAdaptiveAssessmentAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveAssessmentAllocationStore: AdaptiveAssessmentAllocationStore {
        var inner: MemoryAdaptiveAssessmentAllocationStore
        var cache: TTLCache<AdaptiveAssessmentAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveAssessmentAllocationStore, cache: TTLCache<AdaptiveAssessmentAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveAssessmentAllocation? {
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

        func save(_ item: AdaptiveAssessmentAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveAssessmentAllocation] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveAssessmentAllocationStore(_ inner: MemoryAdaptiveAssessmentAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveAssessmentAllocationStore {
        return CachedAdaptiveAssessmentAllocationStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive assessment allocations. Empty fields match all.
    final class AdaptiveAssessmentAllocationQuery {
        var channel: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveAssessmentAllocation) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveAssessmentAllocation]) -> [AdaptiveAssessmentAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveAssessmentAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveAssessmentAllocations(_ store: any AdaptiveAssessmentAllocationStore, query: AdaptiveAssessmentAllocationQuery) -> [AdaptiveAssessmentAllocation] {
        return query.apply(store.list())
    }
}
