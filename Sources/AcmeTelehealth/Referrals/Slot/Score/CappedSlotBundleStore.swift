import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps capped slot bundles by code.
    protocol CappedSlotBundleStore {
        func find(_ code: String) -> CappedSlotBundle?
        func save(_ item: CappedSlotBundle)
        func remove(_ code: String) -> Bool
        func list() -> [CappedSlotBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedSlotBundleStore: CappedSlotBundleStore {
        var items: [String: CappedSlotBundle]
        var order: [String]

        init(items: [String: CappedSlotBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedSlotBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedSlotBundle) {
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

        func list() -> [CappedSlotBundle] {
            var out: [CappedSlotBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedSlotBundleStore() -> any CappedSlotBundleStore {
        return MemoryCappedSlotBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedSlotBundleStore: CappedSlotBundleStore {
        var inner: MemoryCappedSlotBundleStore
        var cache: TTLCache<CappedSlotBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedSlotBundleStore, cache: TTLCache<CappedSlotBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedSlotBundle? {
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

        func save(_ item: CappedSlotBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedSlotBundle] {
            return inner.list()
        }
    }

    static func newCachedCappedSlotBundleStore(_ inner: MemoryCappedSlotBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedSlotBundleStore {
        return CachedCappedSlotBundleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped slot bundles. Empty fields match all.
    final class CappedSlotBundleQuery {
        var name: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedSlotBundle) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedSlotBundle]) -> [CappedSlotBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedSlotBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedSlotBundles(_ store: any CappedSlotBundleStore, query: CappedSlotBundleQuery) -> [CappedSlotBundle] {
        return query.apply(store.list())
    }
}
