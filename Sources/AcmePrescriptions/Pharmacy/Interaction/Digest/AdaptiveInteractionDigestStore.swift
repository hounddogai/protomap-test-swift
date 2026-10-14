import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps adaptive interaction digests by code.
    protocol AdaptiveInteractionDigestStore {
        func find(_ code: String) -> AdaptiveInteractionDigest?
        func save(_ item: AdaptiveInteractionDigest)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveInteractionDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveInteractionDigestStore: AdaptiveInteractionDigestStore {
        var items: [String: AdaptiveInteractionDigest]
        var order: [String]

        init(items: [String: AdaptiveInteractionDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveInteractionDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveInteractionDigest) {
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

        func list() -> [AdaptiveInteractionDigest] {
            var out: [AdaptiveInteractionDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveInteractionDigestStore() -> any AdaptiveInteractionDigestStore {
        return MemoryAdaptiveInteractionDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveInteractionDigestStore: AdaptiveInteractionDigestStore {
        var inner: MemoryAdaptiveInteractionDigestStore
        var cache: TTLCache<AdaptiveInteractionDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveInteractionDigestStore, cache: TTLCache<AdaptiveInteractionDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveInteractionDigest? {
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

        func save(_ item: AdaptiveInteractionDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveInteractionDigest] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveInteractionDigestStore(_ inner: MemoryAdaptiveInteractionDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveInteractionDigestStore {
        return CachedAdaptiveInteractionDigestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive interaction digests. Empty fields match all.
    final class AdaptiveInteractionDigestQuery {
        var locale: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveInteractionDigest) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveInteractionDigest]) -> [AdaptiveInteractionDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveInteractionDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveInteractionDigests(_ store: any AdaptiveInteractionDigestStore, query: AdaptiveInteractionDigestQuery) -> [AdaptiveInteractionDigest] {
        return query.apply(store.list())
    }
}
