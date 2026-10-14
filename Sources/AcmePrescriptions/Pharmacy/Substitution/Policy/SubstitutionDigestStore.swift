import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps substitution digests by code.
    protocol SubstitutionDigestStore {
        func find(_ code: String) -> SubstitutionDigest?
        func save(_ item: SubstitutionDigest)
        func remove(_ code: String) -> Bool
        func list() -> [SubstitutionDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySubstitutionDigestStore: SubstitutionDigestStore {
        var items: [String: SubstitutionDigest]
        var order: [String]

        init(items: [String: SubstitutionDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SubstitutionDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SubstitutionDigest) {
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

        func list() -> [SubstitutionDigest] {
            var out: [SubstitutionDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySubstitutionDigestStore() -> any SubstitutionDigestStore {
        return MemorySubstitutionDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSubstitutionDigestStore: SubstitutionDigestStore {
        var inner: MemorySubstitutionDigestStore
        var cache: TTLCache<SubstitutionDigest>
        var hits: Int
        var misses: Int

        init(inner: MemorySubstitutionDigestStore, cache: TTLCache<SubstitutionDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SubstitutionDigest? {
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

        func save(_ item: SubstitutionDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SubstitutionDigest] {
            return inner.list()
        }
    }

    static func newCachedSubstitutionDigestStore(_ inner: MemorySubstitutionDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SubstitutionDigestStore {
        return CachedSubstitutionDigestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects substitution digests. Empty fields match all.
    final class SubstitutionDigestQuery {
        var category: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SubstitutionDigest) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SubstitutionDigest]) -> [SubstitutionDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SubstitutionDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSubstitutionDigests(_ store: any SubstitutionDigestStore, query: SubstitutionDigestQuery) -> [SubstitutionDigest] {
        return query.apply(store.list())
    }
}
