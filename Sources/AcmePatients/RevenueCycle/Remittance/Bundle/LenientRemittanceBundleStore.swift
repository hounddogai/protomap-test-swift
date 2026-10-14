import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps lenient remittance bundles by code.
    protocol LenientRemittanceBundleStore {
        func find(_ code: String) -> LenientRemittanceBundle?
        func save(_ item: LenientRemittanceBundle)
        func remove(_ code: String) -> Bool
        func list() -> [LenientRemittanceBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientRemittanceBundleStore: LenientRemittanceBundleStore {
        var items: [String: LenientRemittanceBundle]
        var order: [String]

        init(items: [String: LenientRemittanceBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientRemittanceBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientRemittanceBundle) {
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

        func list() -> [LenientRemittanceBundle] {
            var out: [LenientRemittanceBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientRemittanceBundleStore() -> any LenientRemittanceBundleStore {
        return MemoryLenientRemittanceBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientRemittanceBundleStore: LenientRemittanceBundleStore {
        var inner: MemoryLenientRemittanceBundleStore
        var cache: TTLCache<LenientRemittanceBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientRemittanceBundleStore, cache: TTLCache<LenientRemittanceBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientRemittanceBundle? {
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

        func save(_ item: LenientRemittanceBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientRemittanceBundle] {
            return inner.list()
        }
    }

    static func newCachedLenientRemittanceBundleStore(_ inner: MemoryLenientRemittanceBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientRemittanceBundleStore {
        return CachedLenientRemittanceBundleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient remittance bundles. Empty fields match all.
    final class LenientRemittanceBundleQuery {
        var title: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minAmount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientRemittanceBundle) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientRemittanceBundle]) -> [LenientRemittanceBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientRemittanceBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientRemittanceBundles(_ store: any LenientRemittanceBundleStore, query: LenientRemittanceBundleQuery) -> [LenientRemittanceBundle] {
        return query.apply(store.list())
    }
}
