import AcmePlatform
import Foundation

extension Labs {
    /// Keeps accession variances by code.
    protocol AccessionVarianceStore {
        func find(_ code: String) -> AccessionVariance?
        func save(_ item: AccessionVariance)
        func remove(_ code: String) -> Bool
        func list() -> [AccessionVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAccessionVarianceStore: AccessionVarianceStore {
        var items: [String: AccessionVariance]
        var order: [String]

        init(items: [String: AccessionVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AccessionVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AccessionVariance) {
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

        func list() -> [AccessionVariance] {
            var out: [AccessionVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAccessionVarianceStore() -> any AccessionVarianceStore {
        return MemoryAccessionVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAccessionVarianceStore: AccessionVarianceStore {
        var inner: MemoryAccessionVarianceStore
        var cache: TTLCache<AccessionVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryAccessionVarianceStore, cache: TTLCache<AccessionVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AccessionVariance? {
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

        func save(_ item: AccessionVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AccessionVariance] {
            return inner.list()
        }
    }

    static func newCachedAccessionVarianceStore(_ inner: MemoryAccessionVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AccessionVarianceStore {
        return CachedAccessionVarianceStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects accession variances. Empty fields match all.
    final class AccessionVarianceQuery {
        var name: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minCopay: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AccessionVariance) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AccessionVariance]) -> [AccessionVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AccessionVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAccessionVariances(_ store: any AccessionVarianceStore, query: AccessionVarianceQuery) -> [AccessionVariance] {
        return query.apply(store.list())
    }
}
