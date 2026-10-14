import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps pending worklist estimates by code.
    protocol PendingWorklistEstimateStore {
        func find(_ code: String) -> PendingWorklistEstimate?
        func save(_ item: PendingWorklistEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [PendingWorklistEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingWorklistEstimateStore: PendingWorklistEstimateStore {
        var items: [String: PendingWorklistEstimate]
        var order: [String]

        init(items: [String: PendingWorklistEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingWorklistEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingWorklistEstimate) {
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

        func list() -> [PendingWorklistEstimate] {
            var out: [PendingWorklistEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingWorklistEstimateStore() -> any PendingWorklistEstimateStore {
        return MemoryPendingWorklistEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingWorklistEstimateStore: PendingWorklistEstimateStore {
        var inner: MemoryPendingWorklistEstimateStore
        var cache: TTLCache<PendingWorklistEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingWorklistEstimateStore, cache: TTLCache<PendingWorklistEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingWorklistEstimate? {
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

        func save(_ item: PendingWorklistEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingWorklistEstimate] {
            return inner.list()
        }
    }

    static func newCachedPendingWorklistEstimateStore(_ inner: MemoryPendingWorklistEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingWorklistEstimateStore {
        return CachedPendingWorklistEstimateStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending worklist estimates. Empty fields match all.
    final class PendingWorklistEstimateQuery {
        var ward: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingWorklistEstimate) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [PendingWorklistEstimate]) -> [PendingWorklistEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingWorklistEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingWorklistEstimates(_ store: any PendingWorklistEstimateStore, query: PendingWorklistEstimateQuery) -> [PendingWorklistEstimate] {
        return query.apply(store.list())
    }
}
