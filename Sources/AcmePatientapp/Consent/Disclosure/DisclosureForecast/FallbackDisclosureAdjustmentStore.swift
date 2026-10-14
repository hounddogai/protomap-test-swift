import AcmePlatform
import Foundation

extension Consent {
    /// Keeps fallback disclosure adjustments by code.
    protocol FallbackDisclosureAdjustmentStore {
        func find(_ code: String) -> FallbackDisclosureAdjustment?
        func save(_ item: FallbackDisclosureAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackDisclosureAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackDisclosureAdjustmentStore: FallbackDisclosureAdjustmentStore {
        var items: [String: FallbackDisclosureAdjustment]
        var order: [String]

        init(items: [String: FallbackDisclosureAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackDisclosureAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackDisclosureAdjustment) {
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

        func list() -> [FallbackDisclosureAdjustment] {
            var out: [FallbackDisclosureAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackDisclosureAdjustmentStore() -> any FallbackDisclosureAdjustmentStore {
        return MemoryFallbackDisclosureAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackDisclosureAdjustmentStore: FallbackDisclosureAdjustmentStore {
        var inner: MemoryFallbackDisclosureAdjustmentStore
        var cache: TTLCache<FallbackDisclosureAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackDisclosureAdjustmentStore, cache: TTLCache<FallbackDisclosureAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackDisclosureAdjustment? {
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

        func save(_ item: FallbackDisclosureAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackDisclosureAdjustment] {
            return inner.list()
        }
    }

    static func newCachedFallbackDisclosureAdjustmentStore(_ inner: MemoryFallbackDisclosureAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackDisclosureAdjustmentStore {
        return CachedFallbackDisclosureAdjustmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback disclosure adjustments. Empty fields match all.
    final class FallbackDisclosureAdjustmentQuery {
        var region: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackDisclosureAdjustment) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackDisclosureAdjustment]) -> [FallbackDisclosureAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackDisclosureAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackDisclosureAdjustments(_ store: any FallbackDisclosureAdjustmentStore, query: FallbackDisclosureAdjustmentQuery) -> [FallbackDisclosureAdjustment] {
        return query.apply(store.list())
    }
}
