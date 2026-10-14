import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps adaptive handoff variances by code.
    protocol AdaptiveHandoffVarianceStore {
        func find(_ code: String) -> AdaptiveHandoffVariance?
        func save(_ item: AdaptiveHandoffVariance)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveHandoffVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveHandoffVarianceStore: AdaptiveHandoffVarianceStore {
        var items: [String: AdaptiveHandoffVariance]
        var order: [String]

        init(items: [String: AdaptiveHandoffVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveHandoffVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveHandoffVariance) {
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

        func list() -> [AdaptiveHandoffVariance] {
            var out: [AdaptiveHandoffVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveHandoffVarianceStore() -> any AdaptiveHandoffVarianceStore {
        return MemoryAdaptiveHandoffVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveHandoffVarianceStore: AdaptiveHandoffVarianceStore {
        var inner: MemoryAdaptiveHandoffVarianceStore
        var cache: TTLCache<AdaptiveHandoffVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveHandoffVarianceStore, cache: TTLCache<AdaptiveHandoffVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveHandoffVariance? {
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

        func save(_ item: AdaptiveHandoffVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveHandoffVariance] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveHandoffVarianceStore(_ inner: MemoryAdaptiveHandoffVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveHandoffVarianceStore {
        return CachedAdaptiveHandoffVarianceStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive handoff variances. Empty fields match all.
    final class AdaptiveHandoffVarianceQuery {
        var label: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveHandoffVariance) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveHandoffVariance]) -> [AdaptiveHandoffVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveHandoffVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveHandoffVariances(_ store: any AdaptiveHandoffVarianceStore, query: AdaptiveHandoffVarianceQuery) -> [AdaptiveHandoffVariance] {
        return query.apply(store.list())
    }
}
