import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps manual charge mappings by code.
    protocol ManualChargeMappingStore {
        func find(_ code: String) -> ManualChargeMapping?
        func save(_ item: ManualChargeMapping)
        func remove(_ code: String) -> Bool
        func list() -> [ManualChargeMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualChargeMappingStore: ManualChargeMappingStore {
        var items: [String: ManualChargeMapping]
        var order: [String]

        init(items: [String: ManualChargeMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualChargeMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualChargeMapping) {
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

        func list() -> [ManualChargeMapping] {
            var out: [ManualChargeMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualChargeMappingStore() -> any ManualChargeMappingStore {
        return MemoryManualChargeMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualChargeMappingStore: ManualChargeMappingStore {
        var inner: MemoryManualChargeMappingStore
        var cache: TTLCache<ManualChargeMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualChargeMappingStore, cache: TTLCache<ManualChargeMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualChargeMapping? {
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

        func save(_ item: ManualChargeMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualChargeMapping] {
            return inner.list()
        }
    }

    static func newCachedManualChargeMappingStore(_ inner: MemoryManualChargeMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualChargeMappingStore {
        return CachedManualChargeMappingStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual charge mappings. Empty fields match all.
    final class ManualChargeMappingQuery {
        var segment: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minSequence: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualChargeMapping) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualChargeMapping]) -> [ManualChargeMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualChargeMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualChargeMappings(_ store: any ManualChargeMappingStore, query: ManualChargeMappingQuery) -> [ManualChargeMapping] {
        return query.apply(store.list())
    }
}
