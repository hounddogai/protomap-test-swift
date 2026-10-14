import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps primary outreach digests by code.
    protocol PrimaryOutreachDigestStore {
        func find(_ code: String) -> PrimaryOutreachDigest?
        func save(_ item: PrimaryOutreachDigest)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryOutreachDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryOutreachDigestStore: PrimaryOutreachDigestStore {
        var items: [String: PrimaryOutreachDigest]
        var order: [String]

        init(items: [String: PrimaryOutreachDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryOutreachDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryOutreachDigest) {
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

        func list() -> [PrimaryOutreachDigest] {
            var out: [PrimaryOutreachDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryOutreachDigestStore() -> any PrimaryOutreachDigestStore {
        return MemoryPrimaryOutreachDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryOutreachDigestStore: PrimaryOutreachDigestStore {
        var inner: MemoryPrimaryOutreachDigestStore
        var cache: TTLCache<PrimaryOutreachDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryOutreachDigestStore, cache: TTLCache<PrimaryOutreachDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryOutreachDigest? {
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

        func save(_ item: PrimaryOutreachDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryOutreachDigest] {
            return inner.list()
        }
    }

    static func newCachedPrimaryOutreachDigestStore(_ inner: MemoryPrimaryOutreachDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryOutreachDigestStore {
        return CachedPrimaryOutreachDigestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary outreach digests. Empty fields match all.
    final class PrimaryOutreachDigestQuery {
        var ward: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryOutreachDigest) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [PrimaryOutreachDigest]) -> [PrimaryOutreachDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryOutreachDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryOutreachDigests(_ store: any PrimaryOutreachDigestStore, query: PrimaryOutreachDigestQuery) -> [PrimaryOutreachDigest] {
        return query.apply(store.list())
    }
}
