import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps global care protocol digests by code.
    protocol GlobalCareProtocolDigestStore {
        func find(_ code: String) -> GlobalCareProtocolDigest?
        func save(_ item: GlobalCareProtocolDigest)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalCareProtocolDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalCareProtocolDigestStore: GlobalCareProtocolDigestStore {
        var items: [String: GlobalCareProtocolDigest]
        var order: [String]

        init(items: [String: GlobalCareProtocolDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalCareProtocolDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalCareProtocolDigest) {
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

        func list() -> [GlobalCareProtocolDigest] {
            var out: [GlobalCareProtocolDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalCareProtocolDigestStore() -> any GlobalCareProtocolDigestStore {
        return MemoryGlobalCareProtocolDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalCareProtocolDigestStore: GlobalCareProtocolDigestStore {
        var inner: MemoryGlobalCareProtocolDigestStore
        var cache: TTLCache<GlobalCareProtocolDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalCareProtocolDigestStore, cache: TTLCache<GlobalCareProtocolDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalCareProtocolDigest? {
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

        func save(_ item: GlobalCareProtocolDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalCareProtocolDigest] {
            return inner.list()
        }
    }

    static func newCachedGlobalCareProtocolDigestStore(_ inner: MemoryGlobalCareProtocolDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalCareProtocolDigestStore {
        return CachedGlobalCareProtocolDigestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global care protocol digests. Empty fields match all.
    final class GlobalCareProtocolDigestQuery {
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

        func matches(_ item: GlobalCareProtocolDigest) -> Bool {
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

        func apply(_ items: [GlobalCareProtocolDigest]) -> [GlobalCareProtocolDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalCareProtocolDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalCareProtocolDigests(_ store: any GlobalCareProtocolDigestStore, query: GlobalCareProtocolDigestQuery) -> [GlobalCareProtocolDigest] {
        return query.apply(store.list())
    }
}
