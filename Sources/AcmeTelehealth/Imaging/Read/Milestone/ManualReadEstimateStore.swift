import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps manual read estimates by code.
    protocol ManualReadEstimateStore {
        func find(_ code: String) -> ManualReadEstimate?
        func save(_ item: ManualReadEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [ManualReadEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualReadEstimateStore: ManualReadEstimateStore {
        var items: [String: ManualReadEstimate]
        var order: [String]

        init(items: [String: ManualReadEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualReadEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualReadEstimate) {
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

        func list() -> [ManualReadEstimate] {
            var out: [ManualReadEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualReadEstimateStore() -> any ManualReadEstimateStore {
        return MemoryManualReadEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualReadEstimateStore: ManualReadEstimateStore {
        var inner: MemoryManualReadEstimateStore
        var cache: TTLCache<ManualReadEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualReadEstimateStore, cache: TTLCache<ManualReadEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualReadEstimate? {
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

        func save(_ item: ManualReadEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualReadEstimate] {
            return inner.list()
        }
    }

    static func newCachedManualReadEstimateStore(_ inner: MemoryManualReadEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualReadEstimateStore {
        return CachedManualReadEstimateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual read estimates. Empty fields match all.
    final class ManualReadEstimateQuery {
        var title: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualReadEstimate) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualReadEstimate]) -> [ManualReadEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualReadEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualReadEstimates(_ store: any ManualReadEstimateStore, query: ManualReadEstimateQuery) -> [ManualReadEstimate] {
        return query.apply(store.list())
    }
}
