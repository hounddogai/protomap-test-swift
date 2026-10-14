import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps weighted slot bundles by code.
    protocol WeightedSlotBundleStore {
        func find(_ code: String) -> WeightedSlotBundle?
        func save(_ item: WeightedSlotBundle)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedSlotBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedSlotBundleStore: WeightedSlotBundleStore {
        var items: [String: WeightedSlotBundle]
        var order: [String]

        init(items: [String: WeightedSlotBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedSlotBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedSlotBundle) {
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

        func list() -> [WeightedSlotBundle] {
            var out: [WeightedSlotBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedSlotBundleStore() -> any WeightedSlotBundleStore {
        return MemoryWeightedSlotBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedSlotBundleStore: WeightedSlotBundleStore {
        var inner: MemoryWeightedSlotBundleStore
        var cache: TTLCache<WeightedSlotBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedSlotBundleStore, cache: TTLCache<WeightedSlotBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedSlotBundle? {
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

        func save(_ item: WeightedSlotBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedSlotBundle] {
            return inner.list()
        }
    }

    static func newCachedWeightedSlotBundleStore(_ inner: MemoryWeightedSlotBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedSlotBundleStore {
        return CachedWeightedSlotBundleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted slot bundles. Empty fields match all.
    final class WeightedSlotBundleQuery {
        var channel: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minScore: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedSlotBundle) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedSlotBundle]) -> [WeightedSlotBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedSlotBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedSlotBundles(_ store: any WeightedSlotBundleStore, query: WeightedSlotBundleQuery) -> [WeightedSlotBundle] {
        return query.apply(store.list())
    }
}
