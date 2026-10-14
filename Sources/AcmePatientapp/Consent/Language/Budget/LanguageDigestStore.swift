import AcmePlatform
import Foundation

extension Consent {
    /// Keeps language digests by code.
    protocol LanguageDigestStore {
        func find(_ code: String) -> LanguageDigest?
        func save(_ item: LanguageDigest)
        func remove(_ code: String) -> Bool
        func list() -> [LanguageDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLanguageDigestStore: LanguageDigestStore {
        var items: [String: LanguageDigest]
        var order: [String]

        init(items: [String: LanguageDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LanguageDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LanguageDigest) {
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

        func list() -> [LanguageDigest] {
            var out: [LanguageDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLanguageDigestStore() -> any LanguageDigestStore {
        return MemoryLanguageDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLanguageDigestStore: LanguageDigestStore {
        var inner: MemoryLanguageDigestStore
        var cache: TTLCache<LanguageDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryLanguageDigestStore, cache: TTLCache<LanguageDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LanguageDigest? {
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

        func save(_ item: LanguageDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LanguageDigest] {
            return inner.list()
        }
    }

    static func newCachedLanguageDigestStore(_ inner: MemoryLanguageDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LanguageDigestStore {
        return CachedLanguageDigestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects language digests. Empty fields match all.
    final class LanguageDigestQuery {
        var name: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRevision: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LanguageDigest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LanguageDigest]) -> [LanguageDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LanguageDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLanguageDigests(_ store: any LanguageDigestStore, query: LanguageDigestQuery) -> [LanguageDigest] {
        return query.apply(store.list())
    }
}
