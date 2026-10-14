import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps manual remittance rollups by code.
    protocol ManualRemittanceRollupStore {
        func find(_ code: String) -> ManualRemittanceRollup?
        func save(_ item: ManualRemittanceRollup)
        func remove(_ code: String) -> Bool
        func list() -> [ManualRemittanceRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualRemittanceRollupStore: ManualRemittanceRollupStore {
        var items: [String: ManualRemittanceRollup]
        var order: [String]

        init(items: [String: ManualRemittanceRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualRemittanceRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualRemittanceRollup) {
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

        func list() -> [ManualRemittanceRollup] {
            var out: [ManualRemittanceRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualRemittanceRollupStore() -> any ManualRemittanceRollupStore {
        return MemoryManualRemittanceRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualRemittanceRollupStore: ManualRemittanceRollupStore {
        var inner: MemoryManualRemittanceRollupStore
        var cache: TTLCache<ManualRemittanceRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualRemittanceRollupStore, cache: TTLCache<ManualRemittanceRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualRemittanceRollup? {
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

        func save(_ item: ManualRemittanceRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualRemittanceRollup] {
            return inner.list()
        }
    }

    static func newCachedManualRemittanceRollupStore(_ inner: MemoryManualRemittanceRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualRemittanceRollupStore {
        return CachedManualRemittanceRollupStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual remittance rollups. Empty fields match all.
    final class ManualRemittanceRollupQuery {
        var region: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualRemittanceRollup) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualRemittanceRollup]) -> [ManualRemittanceRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualRemittanceRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualRemittanceRollups(_ store: any ManualRemittanceRollupStore, query: ManualRemittanceRollupQuery) -> [ManualRemittanceRollup] {
        return query.apply(store.list())
    }
}
