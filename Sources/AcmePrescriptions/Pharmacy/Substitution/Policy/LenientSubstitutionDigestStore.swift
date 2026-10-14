import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps lenient substitution digests by code.
    protocol LenientSubstitutionDigestStore {
        func find(_ code: String) -> LenientSubstitutionDigest?
        func save(_ item: LenientSubstitutionDigest)
        func remove(_ code: String) -> Bool
        func list() -> [LenientSubstitutionDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientSubstitutionDigestStore: LenientSubstitutionDigestStore {
        var items: [String: LenientSubstitutionDigest]
        var order: [String]

        init(items: [String: LenientSubstitutionDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientSubstitutionDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientSubstitutionDigest) {
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

        func list() -> [LenientSubstitutionDigest] {
            var out: [LenientSubstitutionDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientSubstitutionDigestStore() -> any LenientSubstitutionDigestStore {
        return MemoryLenientSubstitutionDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientSubstitutionDigestStore: LenientSubstitutionDigestStore {
        var inner: MemoryLenientSubstitutionDigestStore
        var cache: TTLCache<LenientSubstitutionDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientSubstitutionDigestStore, cache: TTLCache<LenientSubstitutionDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientSubstitutionDigest? {
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

        func save(_ item: LenientSubstitutionDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientSubstitutionDigest] {
            return inner.list()
        }
    }

    static func newCachedLenientSubstitutionDigestStore(_ inner: MemoryLenientSubstitutionDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientSubstitutionDigestStore {
        return CachedLenientSubstitutionDigestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient substitution digests. Empty fields match all.
    final class LenientSubstitutionDigestQuery {
        var category: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientSubstitutionDigest) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientSubstitutionDigest]) -> [LenientSubstitutionDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientSubstitutionDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientSubstitutionDigests(_ store: any LenientSubstitutionDigestStore, query: LenientSubstitutionDigestQuery) -> [LenientSubstitutionDigest] {
        return query.apply(store.list())
    }
}
