import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps denial bundles by code.
    protocol DenialBundleStore {
        func find(_ code: String) -> DenialBundle?
        func save(_ item: DenialBundle)
        func remove(_ code: String) -> Bool
        func list() -> [DenialBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDenialBundleStore: DenialBundleStore {
        var items: [String: DenialBundle]
        var order: [String]

        init(items: [String: DenialBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DenialBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DenialBundle) {
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

        func list() -> [DenialBundle] {
            var out: [DenialBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDenialBundleStore() -> any DenialBundleStore {
        return MemoryDenialBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDenialBundleStore: DenialBundleStore {
        var inner: MemoryDenialBundleStore
        var cache: TTLCache<DenialBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryDenialBundleStore, cache: TTLCache<DenialBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DenialBundle? {
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

        func save(_ item: DenialBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DenialBundle] {
            return inner.list()
        }
    }

    static func newCachedDenialBundleStore(_ inner: MemoryDenialBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DenialBundleStore {
        return CachedDenialBundleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects denial bundles. Empty fields match all.
    final class DenialBundleQuery {
        var name: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minPriority: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DenialBundle) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DenialBundle]) -> [DenialBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DenialBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDenialBundles(_ store: any DenialBundleStore, query: DenialBundleQuery) -> [DenialBundle] {
        return query.apply(store.list())
    }
}
