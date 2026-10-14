import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps tiered modality variances by code.
    protocol TieredModalityVarianceStore {
        func find(_ code: String) -> TieredModalityVariance?
        func save(_ item: TieredModalityVariance)
        func remove(_ code: String) -> Bool
        func list() -> [TieredModalityVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredModalityVarianceStore: TieredModalityVarianceStore {
        var items: [String: TieredModalityVariance]
        var order: [String]

        init(items: [String: TieredModalityVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredModalityVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredModalityVariance) {
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

        func list() -> [TieredModalityVariance] {
            var out: [TieredModalityVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredModalityVarianceStore() -> any TieredModalityVarianceStore {
        return MemoryTieredModalityVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredModalityVarianceStore: TieredModalityVarianceStore {
        var inner: MemoryTieredModalityVarianceStore
        var cache: TTLCache<TieredModalityVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredModalityVarianceStore, cache: TTLCache<TieredModalityVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredModalityVariance? {
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

        func save(_ item: TieredModalityVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredModalityVariance] {
            return inner.list()
        }
    }

    static func newCachedTieredModalityVarianceStore(_ inner: MemoryTieredModalityVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredModalityVarianceStore {
        return CachedTieredModalityVarianceStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered modality variances. Empty fields match all.
    final class TieredModalityVarianceQuery {
        var country: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minPriority: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredModalityVariance) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [TieredModalityVariance]) -> [TieredModalityVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredModalityVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredModalityVariances(_ store: any TieredModalityVarianceStore, query: TieredModalityVarianceQuery) -> [TieredModalityVariance] {
        return query.apply(store.list())
    }
}
