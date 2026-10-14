import AcmePlatform
import Foundation

extension Labs {
    /// Keeps global accession digests by code.
    protocol GlobalAccessionDigestStore {
        func find(_ code: String) -> GlobalAccessionDigest?
        func save(_ item: GlobalAccessionDigest)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalAccessionDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalAccessionDigestStore: GlobalAccessionDigestStore {
        var items: [String: GlobalAccessionDigest]
        var order: [String]

        init(items: [String: GlobalAccessionDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalAccessionDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalAccessionDigest) {
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

        func list() -> [GlobalAccessionDigest] {
            var out: [GlobalAccessionDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalAccessionDigestStore() -> any GlobalAccessionDigestStore {
        return MemoryGlobalAccessionDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalAccessionDigestStore: GlobalAccessionDigestStore {
        var inner: MemoryGlobalAccessionDigestStore
        var cache: TTLCache<GlobalAccessionDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalAccessionDigestStore, cache: TTLCache<GlobalAccessionDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalAccessionDigest? {
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

        func save(_ item: GlobalAccessionDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalAccessionDigest] {
            return inner.list()
        }
    }

    static func newCachedGlobalAccessionDigestStore(_ inner: MemoryGlobalAccessionDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalAccessionDigestStore {
        return CachedGlobalAccessionDigestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global accession digests. Empty fields match all.
    final class GlobalAccessionDigestQuery {
        var locale: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalAccessionDigest) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalAccessionDigest]) -> [GlobalAccessionDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalAccessionDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalAccessionDigests(_ store: any GlobalAccessionDigestStore, query: GlobalAccessionDigestQuery) -> [GlobalAccessionDigest] {
        return query.apply(store.list())
    }
}
