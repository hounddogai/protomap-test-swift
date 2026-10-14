import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps manual network cycles by code.
    protocol ManualNetworkCycleStore {
        func find(_ code: String) -> ManualNetworkCycle?
        func save(_ item: ManualNetworkCycle)
        func remove(_ code: String) -> Bool
        func list() -> [ManualNetworkCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualNetworkCycleStore: ManualNetworkCycleStore {
        var items: [String: ManualNetworkCycle]
        var order: [String]

        init(items: [String: ManualNetworkCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualNetworkCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualNetworkCycle) {
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

        func list() -> [ManualNetworkCycle] {
            var out: [ManualNetworkCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualNetworkCycleStore() -> any ManualNetworkCycleStore {
        return MemoryManualNetworkCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualNetworkCycleStore: ManualNetworkCycleStore {
        var inner: MemoryManualNetworkCycleStore
        var cache: TTLCache<ManualNetworkCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualNetworkCycleStore, cache: TTLCache<ManualNetworkCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualNetworkCycle? {
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

        func save(_ item: ManualNetworkCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualNetworkCycle] {
            return inner.list()
        }
    }

    static func newCachedManualNetworkCycleStore(_ inner: MemoryManualNetworkCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualNetworkCycleStore {
        return CachedManualNetworkCycleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual network cycles. Empty fields match all.
    final class ManualNetworkCycleQuery {
        var ward: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minRevision: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualNetworkCycle) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualNetworkCycle]) -> [ManualNetworkCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualNetworkCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualNetworkCycles(_ store: any ManualNetworkCycleStore, query: ManualNetworkCycleQuery) -> [ManualNetworkCycle] {
        return query.apply(store.list())
    }
}
