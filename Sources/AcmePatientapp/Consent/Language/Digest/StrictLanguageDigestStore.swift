import AcmePlatform
import Foundation

extension Consent {
    /// Keeps strict language digests by code.
    protocol StrictLanguageDigestStore {
        func find(_ code: String) -> StrictLanguageDigest?
        func save(_ item: StrictLanguageDigest)
        func remove(_ code: String) -> Bool
        func list() -> [StrictLanguageDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictLanguageDigestStore: StrictLanguageDigestStore {
        var items: [String: StrictLanguageDigest]
        var order: [String]

        init(items: [String: StrictLanguageDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictLanguageDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictLanguageDigest) {
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

        func list() -> [StrictLanguageDigest] {
            var out: [StrictLanguageDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictLanguageDigestStore() -> any StrictLanguageDigestStore {
        return MemoryStrictLanguageDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictLanguageDigestStore: StrictLanguageDigestStore {
        var inner: MemoryStrictLanguageDigestStore
        var cache: TTLCache<StrictLanguageDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictLanguageDigestStore, cache: TTLCache<StrictLanguageDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictLanguageDigest? {
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

        func save(_ item: StrictLanguageDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictLanguageDigest] {
            return inner.list()
        }
    }

    static func newCachedStrictLanguageDigestStore(_ inner: MemoryStrictLanguageDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictLanguageDigestStore {
        return CachedStrictLanguageDigestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict language digests. Empty fields match all.
    final class StrictLanguageDigestQuery {
        var region: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictLanguageDigest) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictLanguageDigest]) -> [StrictLanguageDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictLanguageDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictLanguageDigests(_ store: any StrictLanguageDigestStore, query: StrictLanguageDigestQuery) -> [StrictLanguageDigest] {
        return query.apply(store.list())
    }
}
