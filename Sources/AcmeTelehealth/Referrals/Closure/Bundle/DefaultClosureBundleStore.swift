import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps default closure bundles by code.
    protocol DefaultClosureBundleStore {
        func find(_ code: String) -> DefaultClosureBundle?
        func save(_ item: DefaultClosureBundle)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultClosureBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultClosureBundleStore: DefaultClosureBundleStore {
        var items: [String: DefaultClosureBundle]
        var order: [String]

        init(items: [String: DefaultClosureBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultClosureBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultClosureBundle) {
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

        func list() -> [DefaultClosureBundle] {
            var out: [DefaultClosureBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultClosureBundleStore() -> any DefaultClosureBundleStore {
        return MemoryDefaultClosureBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultClosureBundleStore: DefaultClosureBundleStore {
        var inner: MemoryDefaultClosureBundleStore
        var cache: TTLCache<DefaultClosureBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultClosureBundleStore, cache: TTLCache<DefaultClosureBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultClosureBundle? {
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

        func save(_ item: DefaultClosureBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultClosureBundle] {
            return inner.list()
        }
    }

    static func newCachedDefaultClosureBundleStore(_ inner: MemoryDefaultClosureBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultClosureBundleStore {
        return CachedDefaultClosureBundleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default closure bundles. Empty fields match all.
    final class DefaultClosureBundleQuery {
        var source: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minLimit: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultClosureBundle) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultClosureBundle]) -> [DefaultClosureBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultClosureBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultClosureBundles(_ store: any DefaultClosureBundleStore, query: DefaultClosureBundleQuery) -> [DefaultClosureBundle] {
        return query.apply(store.list())
    }
}
