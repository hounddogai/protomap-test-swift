import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps strict credential bundles by code.
    protocol StrictCredentialBundleStore {
        func find(_ code: String) -> StrictCredentialBundle?
        func save(_ item: StrictCredentialBundle)
        func remove(_ code: String) -> Bool
        func list() -> [StrictCredentialBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictCredentialBundleStore: StrictCredentialBundleStore {
        var items: [String: StrictCredentialBundle]
        var order: [String]

        init(items: [String: StrictCredentialBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictCredentialBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictCredentialBundle) {
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

        func list() -> [StrictCredentialBundle] {
            var out: [StrictCredentialBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictCredentialBundleStore() -> any StrictCredentialBundleStore {
        return MemoryStrictCredentialBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictCredentialBundleStore: StrictCredentialBundleStore {
        var inner: MemoryStrictCredentialBundleStore
        var cache: TTLCache<StrictCredentialBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictCredentialBundleStore, cache: TTLCache<StrictCredentialBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictCredentialBundle? {
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

        func save(_ item: StrictCredentialBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictCredentialBundle] {
            return inner.list()
        }
    }

    static func newCachedStrictCredentialBundleStore(_ inner: MemoryStrictCredentialBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictCredentialBundleStore {
        return CachedStrictCredentialBundleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict credential bundles. Empty fields match all.
    final class StrictCredentialBundleQuery {
        var name: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictCredentialBundle) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [StrictCredentialBundle]) -> [StrictCredentialBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictCredentialBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictCredentialBundles(_ store: any StrictCredentialBundleStore, query: StrictCredentialBundleQuery) -> [StrictCredentialBundle] {
        return query.apply(store.list())
    }
}
