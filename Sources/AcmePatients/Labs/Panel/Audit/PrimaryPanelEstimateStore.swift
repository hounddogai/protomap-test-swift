import AcmePlatform
import Foundation

extension Labs {
    /// Keeps primary panel estimates by code.
    protocol PrimaryPanelEstimateStore {
        func find(_ code: String) -> PrimaryPanelEstimate?
        func save(_ item: PrimaryPanelEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryPanelEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryPanelEstimateStore: PrimaryPanelEstimateStore {
        var items: [String: PrimaryPanelEstimate]
        var order: [String]

        init(items: [String: PrimaryPanelEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryPanelEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryPanelEstimate) {
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

        func list() -> [PrimaryPanelEstimate] {
            var out: [PrimaryPanelEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryPanelEstimateStore() -> any PrimaryPanelEstimateStore {
        return MemoryPrimaryPanelEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryPanelEstimateStore: PrimaryPanelEstimateStore {
        var inner: MemoryPrimaryPanelEstimateStore
        var cache: TTLCache<PrimaryPanelEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryPanelEstimateStore, cache: TTLCache<PrimaryPanelEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryPanelEstimate? {
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

        func save(_ item: PrimaryPanelEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryPanelEstimate] {
            return inner.list()
        }
    }

    static func newCachedPrimaryPanelEstimateStore(_ inner: MemoryPrimaryPanelEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryPanelEstimateStore {
        return CachedPrimaryPanelEstimateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary panel estimates. Empty fields match all.
    final class PrimaryPanelEstimateQuery {
        var unit: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryPanelEstimate) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryPanelEstimate]) -> [PrimaryPanelEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryPanelEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryPanelEstimates(_ store: any PrimaryPanelEstimateStore, query: PrimaryPanelEstimateQuery) -> [PrimaryPanelEstimate] {
        return query.apply(store.list())
    }
}
