import AcmePlatform
import Foundation

extension Labs {
    /// Keeps panel estimates by code.
    protocol PanelEstimateStore {
        func find(_ code: String) -> PanelEstimate?
        func save(_ item: PanelEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [PanelEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPanelEstimateStore: PanelEstimateStore {
        var items: [String: PanelEstimate]
        var order: [String]

        init(items: [String: PanelEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PanelEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PanelEstimate) {
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

        func list() -> [PanelEstimate] {
            var out: [PanelEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPanelEstimateStore() -> any PanelEstimateStore {
        return MemoryPanelEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPanelEstimateStore: PanelEstimateStore {
        var inner: MemoryPanelEstimateStore
        var cache: TTLCache<PanelEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryPanelEstimateStore, cache: TTLCache<PanelEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PanelEstimate? {
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

        func save(_ item: PanelEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PanelEstimate] {
            return inner.list()
        }
    }

    static func newCachedPanelEstimateStore(_ inner: MemoryPanelEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PanelEstimateStore {
        return CachedPanelEstimateStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects panel estimates. Empty fields match all.
    final class PanelEstimateQuery {
        var title: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minRefills: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PanelEstimate) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [PanelEstimate]) -> [PanelEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PanelEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPanelEstimates(_ store: any PanelEstimateStore, query: PanelEstimateQuery) -> [PanelEstimate] {
        return query.apply(store.list())
    }
}
