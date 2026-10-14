import AcmePlatform
import Foundation

extension Consent {
    /// Keeps manual witness thresholds by code.
    protocol ManualWitnessThresholdStore {
        func find(_ code: String) -> ManualWitnessThreshold?
        func save(_ item: ManualWitnessThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [ManualWitnessThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualWitnessThresholdStore: ManualWitnessThresholdStore {
        var items: [String: ManualWitnessThreshold]
        var order: [String]

        init(items: [String: ManualWitnessThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualWitnessThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualWitnessThreshold) {
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

        func list() -> [ManualWitnessThreshold] {
            var out: [ManualWitnessThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualWitnessThresholdStore() -> any ManualWitnessThresholdStore {
        return MemoryManualWitnessThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualWitnessThresholdStore: ManualWitnessThresholdStore {
        var inner: MemoryManualWitnessThresholdStore
        var cache: TTLCache<ManualWitnessThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualWitnessThresholdStore, cache: TTLCache<ManualWitnessThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualWitnessThreshold? {
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

        func save(_ item: ManualWitnessThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualWitnessThreshold] {
            return inner.list()
        }
    }

    static func newCachedManualWitnessThresholdStore(_ inner: MemoryManualWitnessThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualWitnessThresholdStore {
        return CachedManualWitnessThresholdStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual witness thresholds. Empty fields match all.
    final class ManualWitnessThresholdQuery {
        var locale: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualWitnessThreshold) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualWitnessThreshold]) -> [ManualWitnessThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualWitnessThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualWitnessThresholds(_ store: any ManualWitnessThresholdStore, query: ManualWitnessThresholdQuery) -> [ManualWitnessThreshold] {
        return query.apply(store.list())
    }
}
