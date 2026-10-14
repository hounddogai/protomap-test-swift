import AcmePlatform
import Foundation

extension Consent {
    /// Keeps witness variances by code.
    protocol WitnessVarianceStore {
        func find(_ code: String) -> WitnessVariance?
        func save(_ item: WitnessVariance)
        func remove(_ code: String) -> Bool
        func list() -> [WitnessVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWitnessVarianceStore: WitnessVarianceStore {
        var items: [String: WitnessVariance]
        var order: [String]

        init(items: [String: WitnessVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WitnessVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WitnessVariance) {
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

        func list() -> [WitnessVariance] {
            var out: [WitnessVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWitnessVarianceStore() -> any WitnessVarianceStore {
        return MemoryWitnessVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWitnessVarianceStore: WitnessVarianceStore {
        var inner: MemoryWitnessVarianceStore
        var cache: TTLCache<WitnessVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryWitnessVarianceStore, cache: TTLCache<WitnessVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WitnessVariance? {
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

        func save(_ item: WitnessVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WitnessVariance] {
            return inner.list()
        }
    }

    static func newCachedWitnessVarianceStore(_ inner: MemoryWitnessVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WitnessVarianceStore {
        return CachedWitnessVarianceStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects witness variances. Empty fields match all.
    final class WitnessVarianceQuery {
        var label: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRetries: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WitnessVariance) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WitnessVariance]) -> [WitnessVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WitnessVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWitnessVariances(_ store: any WitnessVarianceStore, query: WitnessVarianceQuery) -> [WitnessVariance] {
        return query.apply(store.list())
    }
}
