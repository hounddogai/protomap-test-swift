import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps isolation estimates by code.
    protocol IsolationEstimateStore {
        func find(_ code: String) -> IsolationEstimate?
        func save(_ item: IsolationEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [IsolationEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryIsolationEstimateStore: IsolationEstimateStore {
        var items: [String: IsolationEstimate]
        var order: [String]

        init(items: [String: IsolationEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> IsolationEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: IsolationEstimate) {
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

        func list() -> [IsolationEstimate] {
            var out: [IsolationEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryIsolationEstimateStore() -> any IsolationEstimateStore {
        return MemoryIsolationEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedIsolationEstimateStore: IsolationEstimateStore {
        var inner: MemoryIsolationEstimateStore
        var cache: TTLCache<IsolationEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryIsolationEstimateStore, cache: TTLCache<IsolationEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> IsolationEstimate? {
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

        func save(_ item: IsolationEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [IsolationEstimate] {
            return inner.list()
        }
    }

    static func newCachedIsolationEstimateStore(_ inner: MemoryIsolationEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any IsolationEstimateStore {
        return CachedIsolationEstimateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects isolation estimates. Empty fields match all.
    final class IsolationEstimateQuery {
        var ward: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: IsolationEstimate) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [IsolationEstimate]) -> [IsolationEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: IsolationEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findIsolationEstimates(_ store: any IsolationEstimateStore, query: IsolationEstimateQuery) -> [IsolationEstimate] {
        return query.apply(store.list())
    }
}
