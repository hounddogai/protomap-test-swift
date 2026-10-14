import AcmePlatform
import Foundation

extension Labs {
    /// Keeps fallback panel bundles by code.
    protocol FallbackPanelBundleStore {
        func find(_ code: String) -> FallbackPanelBundle?
        func save(_ item: FallbackPanelBundle)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackPanelBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackPanelBundleStore: FallbackPanelBundleStore {
        var items: [String: FallbackPanelBundle]
        var order: [String]

        init(items: [String: FallbackPanelBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackPanelBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackPanelBundle) {
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

        func list() -> [FallbackPanelBundle] {
            var out: [FallbackPanelBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackPanelBundleStore() -> any FallbackPanelBundleStore {
        return MemoryFallbackPanelBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackPanelBundleStore: FallbackPanelBundleStore {
        var inner: MemoryFallbackPanelBundleStore
        var cache: TTLCache<FallbackPanelBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackPanelBundleStore, cache: TTLCache<FallbackPanelBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackPanelBundle? {
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

        func save(_ item: FallbackPanelBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackPanelBundle] {
            return inner.list()
        }
    }

    static func newCachedFallbackPanelBundleStore(_ inner: MemoryFallbackPanelBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackPanelBundleStore {
        return CachedFallbackPanelBundleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback panel bundles. Empty fields match all.
    final class FallbackPanelBundleQuery {
        var ward: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackPanelBundle) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackPanelBundle]) -> [FallbackPanelBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackPanelBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackPanelBundles(_ store: any FallbackPanelBundleStore, query: FallbackPanelBundleQuery) -> [FallbackPanelBundle] {
        return query.apply(store.list())
    }
}
