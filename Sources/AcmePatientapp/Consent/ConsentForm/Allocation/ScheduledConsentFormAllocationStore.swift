import AcmePlatform
import Foundation

extension Consent {
    /// Keeps scheduled consent form allocations by code.
    protocol ScheduledConsentFormAllocationStore {
        func find(_ code: String) -> ScheduledConsentFormAllocation?
        func save(_ item: ScheduledConsentFormAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledConsentFormAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledConsentFormAllocationStore: ScheduledConsentFormAllocationStore {
        var items: [String: ScheduledConsentFormAllocation]
        var order: [String]

        init(items: [String: ScheduledConsentFormAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledConsentFormAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledConsentFormAllocation) {
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

        func list() -> [ScheduledConsentFormAllocation] {
            var out: [ScheduledConsentFormAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledConsentFormAllocationStore() -> any ScheduledConsentFormAllocationStore {
        return MemoryScheduledConsentFormAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledConsentFormAllocationStore: ScheduledConsentFormAllocationStore {
        var inner: MemoryScheduledConsentFormAllocationStore
        var cache: TTLCache<ScheduledConsentFormAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledConsentFormAllocationStore, cache: TTLCache<ScheduledConsentFormAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledConsentFormAllocation? {
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

        func save(_ item: ScheduledConsentFormAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledConsentFormAllocation] {
            return inner.list()
        }
    }

    static func newCachedScheduledConsentFormAllocationStore(_ inner: MemoryScheduledConsentFormAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledConsentFormAllocationStore {
        return CachedScheduledConsentFormAllocationStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled consent form allocations. Empty fields match all.
    final class ScheduledConsentFormAllocationQuery {
        var source: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledConsentFormAllocation) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledConsentFormAllocation]) -> [ScheduledConsentFormAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledConsentFormAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledConsentFormAllocations(_ store: any ScheduledConsentFormAllocationStore, query: ScheduledConsentFormAllocationQuery) -> [ScheduledConsentFormAllocation] {
        return query.apply(store.list())
    }
}
