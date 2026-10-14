import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps closure estimates by code.
    protocol ClosureEstimateStore {
        func find(_ code: String) -> ClosureEstimate?
        func save(_ item: ClosureEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [ClosureEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClosureEstimateStore: ClosureEstimateStore {
        var items: [String: ClosureEstimate]
        var order: [String]

        init(items: [String: ClosureEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClosureEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClosureEstimate) {
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

        func list() -> [ClosureEstimate] {
            var out: [ClosureEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClosureEstimateStore() -> any ClosureEstimateStore {
        return MemoryClosureEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClosureEstimateStore: ClosureEstimateStore {
        var inner: MemoryClosureEstimateStore
        var cache: TTLCache<ClosureEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryClosureEstimateStore, cache: TTLCache<ClosureEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClosureEstimate? {
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

        func save(_ item: ClosureEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClosureEstimate] {
            return inner.list()
        }
    }

    static func newCachedClosureEstimateStore(_ inner: MemoryClosureEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClosureEstimateStore {
        return CachedClosureEstimateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects closure estimates. Empty fields match all.
    final class ClosureEstimateQuery {
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

        func matches(_ item: ClosureEstimate) -> Bool {
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

        func apply(_ items: [ClosureEstimate]) -> [ClosureEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClosureEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClosureEstimates(_ store: any ClosureEstimateStore, query: ClosureEstimateQuery) -> [ClosureEstimate] {
        return query.apply(store.list())
    }
}
