import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps lenient authorization digests by code.
    protocol LenientAuthorizationDigestStore {
        func find(_ code: String) -> LenientAuthorizationDigest?
        func save(_ item: LenientAuthorizationDigest)
        func remove(_ code: String) -> Bool
        func list() -> [LenientAuthorizationDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientAuthorizationDigestStore: LenientAuthorizationDigestStore {
        var items: [String: LenientAuthorizationDigest]
        var order: [String]

        init(items: [String: LenientAuthorizationDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientAuthorizationDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientAuthorizationDigest) {
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

        func list() -> [LenientAuthorizationDigest] {
            var out: [LenientAuthorizationDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientAuthorizationDigestStore() -> any LenientAuthorizationDigestStore {
        return MemoryLenientAuthorizationDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientAuthorizationDigestStore: LenientAuthorizationDigestStore {
        var inner: MemoryLenientAuthorizationDigestStore
        var cache: TTLCache<LenientAuthorizationDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientAuthorizationDigestStore, cache: TTLCache<LenientAuthorizationDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientAuthorizationDigest? {
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

        func save(_ item: LenientAuthorizationDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientAuthorizationDigest] {
            return inner.list()
        }
    }

    static func newCachedLenientAuthorizationDigestStore(_ inner: MemoryLenientAuthorizationDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientAuthorizationDigestStore {
        return CachedLenientAuthorizationDigestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient authorization digests. Empty fields match all.
    final class LenientAuthorizationDigestQuery {
        var label: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientAuthorizationDigest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientAuthorizationDigest]) -> [LenientAuthorizationDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientAuthorizationDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientAuthorizationDigests(_ store: any LenientAuthorizationDigestStore, query: LenientAuthorizationDigestQuery) -> [LenientAuthorizationDigest] {
        return query.apply(store.list())
    }
}
