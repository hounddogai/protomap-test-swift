import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps worklist estimates by code.
    protocol WorklistEstimateStore {
        func find(_ code: String) -> WorklistEstimate?
        func save(_ item: WorklistEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [WorklistEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWorklistEstimateStore: WorklistEstimateStore {
        var items: [String: WorklistEstimate]
        var order: [String]

        init(items: [String: WorklistEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WorklistEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WorklistEstimate) {
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

        func list() -> [WorklistEstimate] {
            var out: [WorklistEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWorklistEstimateStore() -> any WorklistEstimateStore {
        return MemoryWorklistEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWorklistEstimateStore: WorklistEstimateStore {
        var inner: MemoryWorklistEstimateStore
        var cache: TTLCache<WorklistEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryWorklistEstimateStore, cache: TTLCache<WorklistEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WorklistEstimate? {
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

        func save(_ item: WorklistEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WorklistEstimate] {
            return inner.list()
        }
    }

    static func newCachedWorklistEstimateStore(_ inner: MemoryWorklistEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WorklistEstimateStore {
        return CachedWorklistEstimateStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects worklist estimates. Empty fields match all.
    final class WorklistEstimateQuery {
        var name: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WorklistEstimate) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WorklistEstimate]) -> [WorklistEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WorklistEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWorklistEstimates(_ store: any WorklistEstimateStore, query: WorklistEstimateQuery) -> [WorklistEstimate] {
        return query.apply(store.list())
    }
}
