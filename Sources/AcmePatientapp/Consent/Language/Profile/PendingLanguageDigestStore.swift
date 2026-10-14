import AcmePlatform
import Foundation

extension Consent {
    /// Keeps pending language digests by code.
    protocol PendingLanguageDigestStore {
        func find(_ code: String) -> PendingLanguageDigest?
        func save(_ item: PendingLanguageDigest)
        func remove(_ code: String) -> Bool
        func list() -> [PendingLanguageDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingLanguageDigestStore: PendingLanguageDigestStore {
        var items: [String: PendingLanguageDigest]
        var order: [String]

        init(items: [String: PendingLanguageDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingLanguageDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingLanguageDigest) {
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

        func list() -> [PendingLanguageDigest] {
            var out: [PendingLanguageDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingLanguageDigestStore() -> any PendingLanguageDigestStore {
        return MemoryPendingLanguageDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingLanguageDigestStore: PendingLanguageDigestStore {
        var inner: MemoryPendingLanguageDigestStore
        var cache: TTLCache<PendingLanguageDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingLanguageDigestStore, cache: TTLCache<PendingLanguageDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingLanguageDigest? {
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

        func save(_ item: PendingLanguageDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingLanguageDigest] {
            return inner.list()
        }
    }

    static func newCachedPendingLanguageDigestStore(_ inner: MemoryPendingLanguageDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingLanguageDigestStore {
        return CachedPendingLanguageDigestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending language digests. Empty fields match all.
    final class PendingLanguageDigestQuery {
        var name: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minPriority: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingLanguageDigest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingLanguageDigest]) -> [PendingLanguageDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingLanguageDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingLanguageDigests(_ store: any PendingLanguageDigestStore, query: PendingLanguageDigestQuery) -> [PendingLanguageDigest] {
        return query.apply(store.list())
    }
}
