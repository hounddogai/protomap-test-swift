import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps global statement estimates by code.
    protocol GlobalStatementEstimateStore {
        func find(_ code: String) -> GlobalStatementEstimate?
        func save(_ item: GlobalStatementEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalStatementEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalStatementEstimateStore: GlobalStatementEstimateStore {
        var items: [String: GlobalStatementEstimate]
        var order: [String]

        init(items: [String: GlobalStatementEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalStatementEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalStatementEstimate) {
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

        func list() -> [GlobalStatementEstimate] {
            var out: [GlobalStatementEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalStatementEstimateStore() -> any GlobalStatementEstimateStore {
        return MemoryGlobalStatementEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalStatementEstimateStore: GlobalStatementEstimateStore {
        var inner: MemoryGlobalStatementEstimateStore
        var cache: TTLCache<GlobalStatementEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalStatementEstimateStore, cache: TTLCache<GlobalStatementEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalStatementEstimate? {
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

        func save(_ item: GlobalStatementEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalStatementEstimate] {
            return inner.list()
        }
    }

    static func newCachedGlobalStatementEstimateStore(_ inner: MemoryGlobalStatementEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalStatementEstimateStore {
        return CachedGlobalStatementEstimateStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global statement estimates. Empty fields match all.
    final class GlobalStatementEstimateQuery {
        var label: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRefills: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalStatementEstimate) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalStatementEstimate]) -> [GlobalStatementEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalStatementEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalStatementEstimates(_ store: any GlobalStatementEstimateStore, query: GlobalStatementEstimateQuery) -> [GlobalStatementEstimate] {
        return query.apply(store.list())
    }
}
