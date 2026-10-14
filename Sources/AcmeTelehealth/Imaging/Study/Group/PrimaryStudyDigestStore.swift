import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps primary study digests by code.
    protocol PrimaryStudyDigestStore {
        func find(_ code: String) -> PrimaryStudyDigest?
        func save(_ item: PrimaryStudyDigest)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryStudyDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryStudyDigestStore: PrimaryStudyDigestStore {
        var items: [String: PrimaryStudyDigest]
        var order: [String]

        init(items: [String: PrimaryStudyDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryStudyDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryStudyDigest) {
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

        func list() -> [PrimaryStudyDigest] {
            var out: [PrimaryStudyDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryStudyDigestStore() -> any PrimaryStudyDigestStore {
        return MemoryPrimaryStudyDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryStudyDigestStore: PrimaryStudyDigestStore {
        var inner: MemoryPrimaryStudyDigestStore
        var cache: TTLCache<PrimaryStudyDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryStudyDigestStore, cache: TTLCache<PrimaryStudyDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryStudyDigest? {
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

        func save(_ item: PrimaryStudyDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryStudyDigest] {
            return inner.list()
        }
    }

    static func newCachedPrimaryStudyDigestStore(_ inner: MemoryPrimaryStudyDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryStudyDigestStore {
        return CachedPrimaryStudyDigestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary study digests. Empty fields match all.
    final class PrimaryStudyDigestQuery {
        var ward: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minBudget: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryStudyDigest) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryStudyDigest]) -> [PrimaryStudyDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryStudyDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryStudyDigests(_ store: any PrimaryStudyDigestStore, query: PrimaryStudyDigestQuery) -> [PrimaryStudyDigest] {
        return query.apply(store.list())
    }
}
