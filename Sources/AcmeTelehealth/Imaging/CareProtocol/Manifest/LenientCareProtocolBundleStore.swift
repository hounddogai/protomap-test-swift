import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps lenient care protocol bundles by code.
    protocol LenientCareProtocolBundleStore {
        func find(_ code: String) -> LenientCareProtocolBundle?
        func save(_ item: LenientCareProtocolBundle)
        func remove(_ code: String) -> Bool
        func list() -> [LenientCareProtocolBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientCareProtocolBundleStore: LenientCareProtocolBundleStore {
        var items: [String: LenientCareProtocolBundle]
        var order: [String]

        init(items: [String: LenientCareProtocolBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientCareProtocolBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientCareProtocolBundle) {
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

        func list() -> [LenientCareProtocolBundle] {
            var out: [LenientCareProtocolBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientCareProtocolBundleStore() -> any LenientCareProtocolBundleStore {
        return MemoryLenientCareProtocolBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientCareProtocolBundleStore: LenientCareProtocolBundleStore {
        var inner: MemoryLenientCareProtocolBundleStore
        var cache: TTLCache<LenientCareProtocolBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientCareProtocolBundleStore, cache: TTLCache<LenientCareProtocolBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientCareProtocolBundle? {
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

        func save(_ item: LenientCareProtocolBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientCareProtocolBundle] {
            return inner.list()
        }
    }

    static func newCachedLenientCareProtocolBundleStore(_ inner: MemoryLenientCareProtocolBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientCareProtocolBundleStore {
        return CachedLenientCareProtocolBundleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient care protocol bundles. Empty fields match all.
    final class LenientCareProtocolBundleQuery {
        var locale: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientCareProtocolBundle) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientCareProtocolBundle]) -> [LenientCareProtocolBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientCareProtocolBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientCareProtocolBundles(_ store: any LenientCareProtocolBundleStore, query: LenientCareProtocolBundleQuery) -> [LenientCareProtocolBundle] {
        return query.apply(store.list())
    }
}
