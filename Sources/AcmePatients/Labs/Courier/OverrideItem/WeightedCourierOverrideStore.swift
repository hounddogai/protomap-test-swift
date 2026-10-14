import AcmePlatform
import Foundation

extension Labs {
    /// Keeps weighted courier overrides by code.
    protocol WeightedCourierOverrideStore {
        func find(_ code: String) -> WeightedCourierOverride?
        func save(_ item: WeightedCourierOverride)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedCourierOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedCourierOverrideStore: WeightedCourierOverrideStore {
        var items: [String: WeightedCourierOverride]
        var order: [String]

        init(items: [String: WeightedCourierOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedCourierOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedCourierOverride) {
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

        func list() -> [WeightedCourierOverride] {
            var out: [WeightedCourierOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedCourierOverrideStore() -> any WeightedCourierOverrideStore {
        return MemoryWeightedCourierOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedCourierOverrideStore: WeightedCourierOverrideStore {
        var inner: MemoryWeightedCourierOverrideStore
        var cache: TTLCache<WeightedCourierOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedCourierOverrideStore, cache: TTLCache<WeightedCourierOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedCourierOverride? {
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

        func save(_ item: WeightedCourierOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedCourierOverride] {
            return inner.list()
        }
    }

    static func newCachedWeightedCourierOverrideStore(_ inner: MemoryWeightedCourierOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedCourierOverrideStore {
        return CachedWeightedCourierOverrideStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted courier overrides. Empty fields match all.
    final class WeightedCourierOverrideQuery {
        var label: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minLimit: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedCourierOverride) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedCourierOverride]) -> [WeightedCourierOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedCourierOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedCourierOverrides(_ store: any WeightedCourierOverrideStore, query: WeightedCourierOverrideQuery) -> [WeightedCourierOverride] {
        return query.apply(store.list())
    }
}
