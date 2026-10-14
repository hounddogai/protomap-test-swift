import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps lenient claim bundles by code.
    protocol LenientClaimBundleStore {
        func find(_ code: String) -> LenientClaimBundle?
        func save(_ item: LenientClaimBundle)
        func remove(_ code: String) -> Bool
        func list() -> [LenientClaimBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientClaimBundleStore: LenientClaimBundleStore {
        var items: [String: LenientClaimBundle]
        var order: [String]

        init(items: [String: LenientClaimBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientClaimBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientClaimBundle) {
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

        func list() -> [LenientClaimBundle] {
            var out: [LenientClaimBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientClaimBundleStore() -> any LenientClaimBundleStore {
        return MemoryLenientClaimBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientClaimBundleStore: LenientClaimBundleStore {
        var inner: MemoryLenientClaimBundleStore
        var cache: TTLCache<LenientClaimBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientClaimBundleStore, cache: TTLCache<LenientClaimBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientClaimBundle? {
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

        func save(_ item: LenientClaimBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientClaimBundle] {
            return inner.list()
        }
    }

    static func newCachedLenientClaimBundleStore(_ inner: MemoryLenientClaimBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientClaimBundleStore {
        return CachedLenientClaimBundleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient claim bundles. Empty fields match all.
    final class LenientClaimBundleQuery {
        var label: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientClaimBundle) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [LenientClaimBundle]) -> [LenientClaimBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientClaimBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientClaimBundles(_ store: any LenientClaimBundleStore, query: LenientClaimBundleQuery) -> [LenientClaimBundle] {
        return query.apply(store.list())
    }
}
