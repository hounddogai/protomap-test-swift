import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps fallback remittance bundles by code.
    protocol FallbackRemittanceBundleStore {
        func find(_ code: String) -> FallbackRemittanceBundle?
        func save(_ item: FallbackRemittanceBundle)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackRemittanceBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackRemittanceBundleStore: FallbackRemittanceBundleStore {
        var items: [String: FallbackRemittanceBundle]
        var order: [String]

        init(items: [String: FallbackRemittanceBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackRemittanceBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackRemittanceBundle) {
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

        func list() -> [FallbackRemittanceBundle] {
            var out: [FallbackRemittanceBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackRemittanceBundleStore() -> any FallbackRemittanceBundleStore {
        return MemoryFallbackRemittanceBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackRemittanceBundleStore: FallbackRemittanceBundleStore {
        var inner: MemoryFallbackRemittanceBundleStore
        var cache: TTLCache<FallbackRemittanceBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackRemittanceBundleStore, cache: TTLCache<FallbackRemittanceBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackRemittanceBundle? {
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

        func save(_ item: FallbackRemittanceBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackRemittanceBundle] {
            return inner.list()
        }
    }

    static func newCachedFallbackRemittanceBundleStore(_ inner: MemoryFallbackRemittanceBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackRemittanceBundleStore {
        return CachedFallbackRemittanceBundleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback remittance bundles. Empty fields match all.
    final class FallbackRemittanceBundleQuery {
        var category: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minRate: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackRemittanceBundle) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackRemittanceBundle]) -> [FallbackRemittanceBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackRemittanceBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackRemittanceBundles(_ store: any FallbackRemittanceBundleStore, query: FallbackRemittanceBundleQuery) -> [FallbackRemittanceBundle] {
        return query.apply(store.list())
    }
}
