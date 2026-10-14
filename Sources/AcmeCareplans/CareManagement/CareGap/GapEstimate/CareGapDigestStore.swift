import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps care gap digests by code.
    protocol CareGapDigestStore {
        func find(_ code: String) -> CareGapDigest?
        func save(_ item: CareGapDigest)
        func remove(_ code: String) -> Bool
        func list() -> [CareGapDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareGapDigestStore: CareGapDigestStore {
        var items: [String: CareGapDigest]
        var order: [String]

        init(items: [String: CareGapDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareGapDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareGapDigest) {
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

        func list() -> [CareGapDigest] {
            var out: [CareGapDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareGapDigestStore() -> any CareGapDigestStore {
        return MemoryCareGapDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareGapDigestStore: CareGapDigestStore {
        var inner: MemoryCareGapDigestStore
        var cache: TTLCache<CareGapDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareGapDigestStore, cache: TTLCache<CareGapDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareGapDigest? {
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

        func save(_ item: CareGapDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareGapDigest] {
            return inner.list()
        }
    }

    static func newCachedCareGapDigestStore(_ inner: MemoryCareGapDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareGapDigestStore {
        return CachedCareGapDigestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care gap digests. Empty fields match all.
    final class CareGapDigestQuery {
        var region: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareGapDigest) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [CareGapDigest]) -> [CareGapDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareGapDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareGapDigests(_ store: any CareGapDigestStore, query: CareGapDigestQuery) -> [CareGapDigest] {
        return query.apply(store.list())
    }
}
