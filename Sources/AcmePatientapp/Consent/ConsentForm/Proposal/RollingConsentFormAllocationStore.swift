import AcmePlatform
import Foundation

extension Consent {
    /// Keeps rolling consent form allocations by code.
    protocol RollingConsentFormAllocationStore {
        func find(_ code: String) -> RollingConsentFormAllocation?
        func save(_ item: RollingConsentFormAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [RollingConsentFormAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingConsentFormAllocationStore: RollingConsentFormAllocationStore {
        var items: [String: RollingConsentFormAllocation]
        var order: [String]

        init(items: [String: RollingConsentFormAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingConsentFormAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingConsentFormAllocation) {
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

        func list() -> [RollingConsentFormAllocation] {
            var out: [RollingConsentFormAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingConsentFormAllocationStore() -> any RollingConsentFormAllocationStore {
        return MemoryRollingConsentFormAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingConsentFormAllocationStore: RollingConsentFormAllocationStore {
        var inner: MemoryRollingConsentFormAllocationStore
        var cache: TTLCache<RollingConsentFormAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingConsentFormAllocationStore, cache: TTLCache<RollingConsentFormAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingConsentFormAllocation? {
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

        func save(_ item: RollingConsentFormAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingConsentFormAllocation] {
            return inner.list()
        }
    }

    static func newCachedRollingConsentFormAllocationStore(_ inner: MemoryRollingConsentFormAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingConsentFormAllocationStore {
        return CachedRollingConsentFormAllocationStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling consent form allocations. Empty fields match all.
    final class RollingConsentFormAllocationQuery {
        var label: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingConsentFormAllocation) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingConsentFormAllocation]) -> [RollingConsentFormAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingConsentFormAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingConsentFormAllocations(_ store: any RollingConsentFormAllocationStore, query: RollingConsentFormAllocationQuery) -> [RollingConsentFormAllocation] {
        return query.apply(store.list())
    }
}
