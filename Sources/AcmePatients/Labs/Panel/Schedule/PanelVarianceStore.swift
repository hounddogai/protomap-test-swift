import AcmePlatform
import Foundation

extension Labs {
    /// Keeps panel variances by code.
    protocol PanelVarianceStore {
        func find(_ code: String) -> PanelVariance?
        func save(_ item: PanelVariance)
        func remove(_ code: String) -> Bool
        func list() -> [PanelVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPanelVarianceStore: PanelVarianceStore {
        var items: [String: PanelVariance]
        var order: [String]

        init(items: [String: PanelVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PanelVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PanelVariance) {
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

        func list() -> [PanelVariance] {
            var out: [PanelVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPanelVarianceStore() -> any PanelVarianceStore {
        return MemoryPanelVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPanelVarianceStore: PanelVarianceStore {
        var inner: MemoryPanelVarianceStore
        var cache: TTLCache<PanelVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryPanelVarianceStore, cache: TTLCache<PanelVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PanelVariance? {
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

        func save(_ item: PanelVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PanelVariance] {
            return inner.list()
        }
    }

    static func newCachedPanelVarianceStore(_ inner: MemoryPanelVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PanelVarianceStore {
        return CachedPanelVarianceStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects panel variances. Empty fields match all.
    final class PanelVarianceQuery {
        var label: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PanelVariance) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [PanelVariance]) -> [PanelVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PanelVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPanelVariances(_ store: any PanelVarianceStore, query: PanelVarianceQuery) -> [PanelVariance] {
        return query.apply(store.list())
    }
}
