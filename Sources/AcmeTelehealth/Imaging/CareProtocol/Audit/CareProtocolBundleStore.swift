import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps care protocol bundles by code.
    protocol CareProtocolBundleStore {
        func find(_ code: String) -> CareProtocolBundle?
        func save(_ item: CareProtocolBundle)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolBundleStore: CareProtocolBundleStore {
        var items: [String: CareProtocolBundle]
        var order: [String]

        init(items: [String: CareProtocolBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolBundle) {
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

        func list() -> [CareProtocolBundle] {
            var out: [CareProtocolBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolBundleStore() -> any CareProtocolBundleStore {
        return MemoryCareProtocolBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolBundleStore: CareProtocolBundleStore {
        var inner: MemoryCareProtocolBundleStore
        var cache: TTLCache<CareProtocolBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolBundleStore, cache: TTLCache<CareProtocolBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolBundle? {
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

        func save(_ item: CareProtocolBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolBundle] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolBundleStore(_ inner: MemoryCareProtocolBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolBundleStore {
        return CachedCareProtocolBundleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol bundles. Empty fields match all.
    final class CareProtocolBundleQuery {
        var channel: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minScore: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolBundle) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [CareProtocolBundle]) -> [CareProtocolBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolBundles(_ store: any CareProtocolBundleStore, query: CareProtocolBundleQuery) -> [CareProtocolBundle] {
        return query.apply(store.list())
    }
}
