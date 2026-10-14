import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps manual claim estimates by code.
    protocol ManualClaimEstimateStore {
        func find(_ code: String) -> ManualClaimEstimate?
        func save(_ item: ManualClaimEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [ManualClaimEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualClaimEstimateStore: ManualClaimEstimateStore {
        var items: [String: ManualClaimEstimate]
        var order: [String]

        init(items: [String: ManualClaimEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualClaimEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualClaimEstimate) {
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

        func list() -> [ManualClaimEstimate] {
            var out: [ManualClaimEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualClaimEstimateStore() -> any ManualClaimEstimateStore {
        return MemoryManualClaimEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualClaimEstimateStore: ManualClaimEstimateStore {
        var inner: MemoryManualClaimEstimateStore
        var cache: TTLCache<ManualClaimEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualClaimEstimateStore, cache: TTLCache<ManualClaimEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualClaimEstimate? {
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

        func save(_ item: ManualClaimEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualClaimEstimate] {
            return inner.list()
        }
    }

    static func newCachedManualClaimEstimateStore(_ inner: MemoryManualClaimEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualClaimEstimateStore {
        return CachedManualClaimEstimateStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual claim estimates. Empty fields match all.
    final class ManualClaimEstimateQuery {
        var name: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualClaimEstimate) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualClaimEstimate]) -> [ManualClaimEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualClaimEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualClaimEstimates(_ store: any ManualClaimEstimateStore, query: ManualClaimEstimateQuery) -> [ManualClaimEstimate] {
        return query.apply(store.list())
    }
}
