import AcmePlatform
import Foundation

extension Consent {
    /// Keeps revocation digests by code.
    protocol RevocationDigestStore {
        func find(_ code: String) -> RevocationDigest?
        func save(_ item: RevocationDigest)
        func remove(_ code: String) -> Bool
        func list() -> [RevocationDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRevocationDigestStore: RevocationDigestStore {
        var items: [String: RevocationDigest]
        var order: [String]

        init(items: [String: RevocationDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RevocationDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RevocationDigest) {
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

        func list() -> [RevocationDigest] {
            var out: [RevocationDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRevocationDigestStore() -> any RevocationDigestStore {
        return MemoryRevocationDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRevocationDigestStore: RevocationDigestStore {
        var inner: MemoryRevocationDigestStore
        var cache: TTLCache<RevocationDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryRevocationDigestStore, cache: TTLCache<RevocationDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RevocationDigest? {
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

        func save(_ item: RevocationDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RevocationDigest] {
            return inner.list()
        }
    }

    static func newCachedRevocationDigestStore(_ inner: MemoryRevocationDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RevocationDigestStore {
        return CachedRevocationDigestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects revocation digests. Empty fields match all.
    final class RevocationDigestQuery {
        var segment: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RevocationDigest) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [RevocationDigest]) -> [RevocationDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RevocationDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRevocationDigests(_ store: any RevocationDigestStore, query: RevocationDigestQuery) -> [RevocationDigest] {
        return query.apply(store.list())
    }
}
