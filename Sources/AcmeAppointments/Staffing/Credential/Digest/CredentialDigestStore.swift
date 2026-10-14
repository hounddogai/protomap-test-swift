import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps credential digests by code.
    protocol CredentialDigestStore {
        func find(_ code: String) -> CredentialDigest?
        func save(_ item: CredentialDigest)
        func remove(_ code: String) -> Bool
        func list() -> [CredentialDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCredentialDigestStore: CredentialDigestStore {
        var items: [String: CredentialDigest]
        var order: [String]

        init(items: [String: CredentialDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CredentialDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CredentialDigest) {
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

        func list() -> [CredentialDigest] {
            var out: [CredentialDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCredentialDigestStore() -> any CredentialDigestStore {
        return MemoryCredentialDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCredentialDigestStore: CredentialDigestStore {
        var inner: MemoryCredentialDigestStore
        var cache: TTLCache<CredentialDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryCredentialDigestStore, cache: TTLCache<CredentialDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CredentialDigest? {
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

        func save(_ item: CredentialDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CredentialDigest] {
            return inner.list()
        }
    }

    static func newCachedCredentialDigestStore(_ inner: MemoryCredentialDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CredentialDigestStore {
        return CachedCredentialDigestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects credential digests. Empty fields match all.
    final class CredentialDigestQuery {
        var title: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CredentialDigest) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [CredentialDigest]) -> [CredentialDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CredentialDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCredentialDigests(_ store: any CredentialDigestStore, query: CredentialDigestQuery) -> [CredentialDigest] {
        return query.apply(store.list())
    }
}
