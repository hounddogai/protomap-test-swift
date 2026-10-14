import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps handoff variances by code.
    protocol HandoffVarianceStore {
        func find(_ code: String) -> HandoffVariance?
        func save(_ item: HandoffVariance)
        func remove(_ code: String) -> Bool
        func list() -> [HandoffVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryHandoffVarianceStore: HandoffVarianceStore {
        var items: [String: HandoffVariance]
        var order: [String]

        init(items: [String: HandoffVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> HandoffVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: HandoffVariance) {
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

        func list() -> [HandoffVariance] {
            var out: [HandoffVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryHandoffVarianceStore() -> any HandoffVarianceStore {
        return MemoryHandoffVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedHandoffVarianceStore: HandoffVarianceStore {
        var inner: MemoryHandoffVarianceStore
        var cache: TTLCache<HandoffVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryHandoffVarianceStore, cache: TTLCache<HandoffVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> HandoffVariance? {
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

        func save(_ item: HandoffVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [HandoffVariance] {
            return inner.list()
        }
    }

    static func newCachedHandoffVarianceStore(_ inner: MemoryHandoffVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any HandoffVarianceStore {
        return CachedHandoffVarianceStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects handoff variances. Empty fields match all.
    final class HandoffVarianceQuery {
        var country: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: HandoffVariance) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [HandoffVariance]) -> [HandoffVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: HandoffVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findHandoffVariances(_ store: any HandoffVarianceStore, query: HandoffVarianceQuery) -> [HandoffVariance] {
        return query.apply(store.list())
    }
}
