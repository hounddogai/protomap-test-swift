import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps task estimates by code.
    protocol TaskEstimateStore {
        func find(_ code: String) -> TaskEstimate?
        func save(_ item: TaskEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [TaskEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTaskEstimateStore: TaskEstimateStore {
        var items: [String: TaskEstimate]
        var order: [String]

        init(items: [String: TaskEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TaskEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TaskEstimate) {
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

        func list() -> [TaskEstimate] {
            var out: [TaskEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTaskEstimateStore() -> any TaskEstimateStore {
        return MemoryTaskEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTaskEstimateStore: TaskEstimateStore {
        var inner: MemoryTaskEstimateStore
        var cache: TTLCache<TaskEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryTaskEstimateStore, cache: TTLCache<TaskEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TaskEstimate? {
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

        func save(_ item: TaskEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TaskEstimate] {
            return inner.list()
        }
    }

    static func newCachedTaskEstimateStore(_ inner: MemoryTaskEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TaskEstimateStore {
        return CachedTaskEstimateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects task estimates. Empty fields match all.
    final class TaskEstimateQuery {
        var category: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TaskEstimate) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TaskEstimate]) -> [TaskEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TaskEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTaskEstimates(_ store: any TaskEstimateStore, query: TaskEstimateQuery) -> [TaskEstimate] {
        return query.apply(store.list())
    }
}
