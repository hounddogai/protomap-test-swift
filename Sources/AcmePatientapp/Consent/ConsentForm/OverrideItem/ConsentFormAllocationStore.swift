import AcmePlatform
import Foundation

extension Consent {
    /// Keeps consent form allocations by code.
    protocol ConsentFormAllocationStore {
        func find(_ code: String) -> ConsentFormAllocation?
        func save(_ item: ConsentFormAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [ConsentFormAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryConsentFormAllocationStore: ConsentFormAllocationStore {
        var items: [String: ConsentFormAllocation]
        var order: [String]

        init(items: [String: ConsentFormAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ConsentFormAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ConsentFormAllocation) {
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

        func list() -> [ConsentFormAllocation] {
            var out: [ConsentFormAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryConsentFormAllocationStore() -> any ConsentFormAllocationStore {
        return MemoryConsentFormAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedConsentFormAllocationStore: ConsentFormAllocationStore {
        var inner: MemoryConsentFormAllocationStore
        var cache: TTLCache<ConsentFormAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryConsentFormAllocationStore, cache: TTLCache<ConsentFormAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ConsentFormAllocation? {
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

        func save(_ item: ConsentFormAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ConsentFormAllocation] {
            return inner.list()
        }
    }

    static func newCachedConsentFormAllocationStore(_ inner: MemoryConsentFormAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ConsentFormAllocationStore {
        return CachedConsentFormAllocationStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects consent form allocations. Empty fields match all.
    final class ConsentFormAllocationQuery {
        var facility: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ConsentFormAllocation) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ConsentFormAllocation]) -> [ConsentFormAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ConsentFormAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findConsentFormAllocations(_ store: any ConsentFormAllocationStore, query: ConsentFormAllocationQuery) -> [ConsentFormAllocation] {
        return query.apply(store.list())
    }
}
