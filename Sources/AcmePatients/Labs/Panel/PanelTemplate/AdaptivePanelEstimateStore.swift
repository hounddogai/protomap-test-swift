import AcmePlatform
import Foundation

extension Labs {
    /// Keeps adaptive panel estimates by code.
    protocol AdaptivePanelEstimateStore {
        func find(_ code: String) -> AdaptivePanelEstimate?
        func save(_ item: AdaptivePanelEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptivePanelEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptivePanelEstimateStore: AdaptivePanelEstimateStore {
        var items: [String: AdaptivePanelEstimate]
        var order: [String]

        init(items: [String: AdaptivePanelEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptivePanelEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptivePanelEstimate) {
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

        func list() -> [AdaptivePanelEstimate] {
            var out: [AdaptivePanelEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptivePanelEstimateStore() -> any AdaptivePanelEstimateStore {
        return MemoryAdaptivePanelEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptivePanelEstimateStore: AdaptivePanelEstimateStore {
        var inner: MemoryAdaptivePanelEstimateStore
        var cache: TTLCache<AdaptivePanelEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptivePanelEstimateStore, cache: TTLCache<AdaptivePanelEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptivePanelEstimate? {
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

        func save(_ item: AdaptivePanelEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptivePanelEstimate] {
            return inner.list()
        }
    }

    static func newCachedAdaptivePanelEstimateStore(_ inner: MemoryAdaptivePanelEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptivePanelEstimateStore {
        return CachedAdaptivePanelEstimateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive panel estimates. Empty fields match all.
    final class AdaptivePanelEstimateQuery {
        var label: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minPriority: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptivePanelEstimate) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptivePanelEstimate]) -> [AdaptivePanelEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptivePanelEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptivePanelEstimates(_ store: any AdaptivePanelEstimateStore, query: AdaptivePanelEstimateQuery) -> [AdaptivePanelEstimate] {
        return query.apply(store.list())
    }
}
