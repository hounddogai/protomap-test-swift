import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps lenient inventory digests by code.
    protocol LenientInventoryDigestStore {
        func find(_ code: String) -> LenientInventoryDigest?
        func save(_ item: LenientInventoryDigest)
        func remove(_ code: String) -> Bool
        func list() -> [LenientInventoryDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientInventoryDigestStore: LenientInventoryDigestStore {
        var items: [String: LenientInventoryDigest]
        var order: [String]

        init(items: [String: LenientInventoryDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientInventoryDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientInventoryDigest) {
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

        func list() -> [LenientInventoryDigest] {
            var out: [LenientInventoryDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientInventoryDigestStore() -> any LenientInventoryDigestStore {
        return MemoryLenientInventoryDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientInventoryDigestStore: LenientInventoryDigestStore {
        var inner: MemoryLenientInventoryDigestStore
        var cache: TTLCache<LenientInventoryDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientInventoryDigestStore, cache: TTLCache<LenientInventoryDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientInventoryDigest? {
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

        func save(_ item: LenientInventoryDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientInventoryDigest] {
            return inner.list()
        }
    }

    static func newCachedLenientInventoryDigestStore(_ inner: MemoryLenientInventoryDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientInventoryDigestStore {
        return CachedLenientInventoryDigestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient inventory digests. Empty fields match all.
    final class LenientInventoryDigestQuery {
        var label: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientInventoryDigest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientInventoryDigest]) -> [LenientInventoryDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientInventoryDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientInventoryDigests(_ store: any LenientInventoryDigestStore, query: LenientInventoryDigestQuery) -> [LenientInventoryDigest] {
        return query.apply(store.list())
    }
}
