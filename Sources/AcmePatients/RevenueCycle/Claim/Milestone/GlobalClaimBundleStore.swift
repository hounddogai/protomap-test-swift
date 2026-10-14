import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps global claim bundles by code.
    protocol GlobalClaimBundleStore {
        func find(_ code: String) -> GlobalClaimBundle?
        func save(_ item: GlobalClaimBundle)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalClaimBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalClaimBundleStore: GlobalClaimBundleStore {
        var items: [String: GlobalClaimBundle]
        var order: [String]

        init(items: [String: GlobalClaimBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalClaimBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalClaimBundle) {
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

        func list() -> [GlobalClaimBundle] {
            var out: [GlobalClaimBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalClaimBundleStore() -> any GlobalClaimBundleStore {
        return MemoryGlobalClaimBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalClaimBundleStore: GlobalClaimBundleStore {
        var inner: MemoryGlobalClaimBundleStore
        var cache: TTLCache<GlobalClaimBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalClaimBundleStore, cache: TTLCache<GlobalClaimBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalClaimBundle? {
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

        func save(_ item: GlobalClaimBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalClaimBundle] {
            return inner.list()
        }
    }

    static func newCachedGlobalClaimBundleStore(_ inner: MemoryGlobalClaimBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalClaimBundleStore {
        return CachedGlobalClaimBundleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global claim bundles. Empty fields match all.
    final class GlobalClaimBundleQuery {
        var name: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minScore: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalClaimBundle) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [GlobalClaimBundle]) -> [GlobalClaimBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalClaimBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalClaimBundles(_ store: any GlobalClaimBundleStore, query: GlobalClaimBundleQuery) -> [GlobalClaimBundle] {
        return query.apply(store.list())
    }
}
