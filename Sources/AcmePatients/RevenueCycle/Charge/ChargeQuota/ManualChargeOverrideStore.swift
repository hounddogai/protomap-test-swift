import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps manual charge overrides by code.
    protocol ManualChargeOverrideStore {
        func find(_ code: String) -> ManualChargeOverride?
        func save(_ item: ManualChargeOverride)
        func remove(_ code: String) -> Bool
        func list() -> [ManualChargeOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualChargeOverrideStore: ManualChargeOverrideStore {
        var items: [String: ManualChargeOverride]
        var order: [String]

        init(items: [String: ManualChargeOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualChargeOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualChargeOverride) {
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

        func list() -> [ManualChargeOverride] {
            var out: [ManualChargeOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualChargeOverrideStore() -> any ManualChargeOverrideStore {
        return MemoryManualChargeOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualChargeOverrideStore: ManualChargeOverrideStore {
        var inner: MemoryManualChargeOverrideStore
        var cache: TTLCache<ManualChargeOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualChargeOverrideStore, cache: TTLCache<ManualChargeOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualChargeOverride? {
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

        func save(_ item: ManualChargeOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualChargeOverride] {
            return inner.list()
        }
    }

    static func newCachedManualChargeOverrideStore(_ inner: MemoryManualChargeOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualChargeOverrideStore {
        return CachedManualChargeOverrideStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual charge overrides. Empty fields match all.
    final class ManualChargeOverrideQuery {
        var category: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualChargeOverride) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualChargeOverride]) -> [ManualChargeOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualChargeOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualChargeOverrides(_ store: any ManualChargeOverrideStore, query: ManualChargeOverrideQuery) -> [ManualChargeOverride] {
        return query.apply(store.list())
    }
}
