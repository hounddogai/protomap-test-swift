import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps closure bundles by code.
    protocol ClosureBundleStore {
        func find(_ code: String) -> ClosureBundle?
        func save(_ item: ClosureBundle)
        func remove(_ code: String) -> Bool
        func list() -> [ClosureBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClosureBundleStore: ClosureBundleStore {
        var items: [String: ClosureBundle]
        var order: [String]

        init(items: [String: ClosureBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClosureBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClosureBundle) {
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

        func list() -> [ClosureBundle] {
            var out: [ClosureBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClosureBundleStore() -> any ClosureBundleStore {
        return MemoryClosureBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClosureBundleStore: ClosureBundleStore {
        var inner: MemoryClosureBundleStore
        var cache: TTLCache<ClosureBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryClosureBundleStore, cache: TTLCache<ClosureBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClosureBundle? {
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

        func save(_ item: ClosureBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClosureBundle] {
            return inner.list()
        }
    }

    static func newCachedClosureBundleStore(_ inner: MemoryClosureBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClosureBundleStore {
        return CachedClosureBundleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects closure bundles. Empty fields match all.
    final class ClosureBundleQuery {
        var title: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClosureBundle) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ClosureBundle]) -> [ClosureBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClosureBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClosureBundles(_ store: any ClosureBundleStore, query: ClosureBundleQuery) -> [ClosureBundle] {
        return query.apply(store.list())
    }
}
