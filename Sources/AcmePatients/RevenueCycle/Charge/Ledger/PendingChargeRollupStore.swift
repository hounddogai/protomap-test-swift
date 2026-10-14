import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps pending charge rollups by code.
    protocol PendingChargeRollupStore {
        func find(_ code: String) -> PendingChargeRollup?
        func save(_ item: PendingChargeRollup)
        func remove(_ code: String) -> Bool
        func list() -> [PendingChargeRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingChargeRollupStore: PendingChargeRollupStore {
        var items: [String: PendingChargeRollup]
        var order: [String]

        init(items: [String: PendingChargeRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingChargeRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingChargeRollup) {
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

        func list() -> [PendingChargeRollup] {
            var out: [PendingChargeRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingChargeRollupStore() -> any PendingChargeRollupStore {
        return MemoryPendingChargeRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingChargeRollupStore: PendingChargeRollupStore {
        var inner: MemoryPendingChargeRollupStore
        var cache: TTLCache<PendingChargeRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingChargeRollupStore, cache: TTLCache<PendingChargeRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingChargeRollup? {
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

        func save(_ item: PendingChargeRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingChargeRollup] {
            return inner.list()
        }
    }

    static func newCachedPendingChargeRollupStore(_ inner: MemoryPendingChargeRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingChargeRollupStore {
        return CachedPendingChargeRollupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending charge rollups. Empty fields match all.
    final class PendingChargeRollupQuery {
        var label: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingChargeRollup) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingChargeRollup]) -> [PendingChargeRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingChargeRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingChargeRollups(_ store: any PendingChargeRollupStore, query: PendingChargeRollupQuery) -> [PendingChargeRollup] {
        return query.apply(store.list())
    }
}
