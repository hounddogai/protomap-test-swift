import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps care protocol digests by code.
    protocol CareProtocolDigestStore {
        func find(_ code: String) -> CareProtocolDigest?
        func save(_ item: CareProtocolDigest)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolDigestStore: CareProtocolDigestStore {
        var items: [String: CareProtocolDigest]
        var order: [String]

        init(items: [String: CareProtocolDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolDigest) {
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

        func list() -> [CareProtocolDigest] {
            var out: [CareProtocolDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolDigestStore() -> any CareProtocolDigestStore {
        return MemoryCareProtocolDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolDigestStore: CareProtocolDigestStore {
        var inner: MemoryCareProtocolDigestStore
        var cache: TTLCache<CareProtocolDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolDigestStore, cache: TTLCache<CareProtocolDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolDigest? {
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

        func save(_ item: CareProtocolDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolDigest] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolDigestStore(_ inner: MemoryCareProtocolDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolDigestStore {
        return CachedCareProtocolDigestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol digests. Empty fields match all.
    final class CareProtocolDigestQuery {
        var label: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minAmount: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolDigest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareProtocolDigest]) -> [CareProtocolDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolDigests(_ store: any CareProtocolDigestStore, query: CareProtocolDigestQuery) -> [CareProtocolDigest] {
        return query.apply(store.list())
    }
}
