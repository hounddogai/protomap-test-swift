import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps strict substitution thresholds by code.
    protocol StrictSubstitutionThresholdStore {
        func find(_ code: String) -> StrictSubstitutionThreshold?
        func save(_ item: StrictSubstitutionThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [StrictSubstitutionThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictSubstitutionThresholdStore: StrictSubstitutionThresholdStore {
        var items: [String: StrictSubstitutionThreshold]
        var order: [String]

        init(items: [String: StrictSubstitutionThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictSubstitutionThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictSubstitutionThreshold) {
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

        func list() -> [StrictSubstitutionThreshold] {
            var out: [StrictSubstitutionThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictSubstitutionThresholdStore() -> any StrictSubstitutionThresholdStore {
        return MemoryStrictSubstitutionThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictSubstitutionThresholdStore: StrictSubstitutionThresholdStore {
        var inner: MemoryStrictSubstitutionThresholdStore
        var cache: TTLCache<StrictSubstitutionThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictSubstitutionThresholdStore, cache: TTLCache<StrictSubstitutionThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictSubstitutionThreshold? {
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

        func save(_ item: StrictSubstitutionThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictSubstitutionThreshold] {
            return inner.list()
        }
    }

    static func newCachedStrictSubstitutionThresholdStore(_ inner: MemoryStrictSubstitutionThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictSubstitutionThresholdStore {
        return CachedStrictSubstitutionThresholdStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict substitution thresholds. Empty fields match all.
    final class StrictSubstitutionThresholdQuery {
        var label: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictSubstitutionThreshold) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [StrictSubstitutionThreshold]) -> [StrictSubstitutionThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictSubstitutionThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictSubstitutionThresholds(_ store: any StrictSubstitutionThresholdStore, query: StrictSubstitutionThresholdQuery) -> [StrictSubstitutionThreshold] {
        return query.apply(store.list())
    }
}
