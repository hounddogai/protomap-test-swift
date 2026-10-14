import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps regional follow up digests by code.
    protocol RegionalFollowUpDigestStore {
        func find(_ code: String) -> RegionalFollowUpDigest?
        func save(_ item: RegionalFollowUpDigest)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalFollowUpDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalFollowUpDigestStore: RegionalFollowUpDigestStore {
        var items: [String: RegionalFollowUpDigest]
        var order: [String]

        init(items: [String: RegionalFollowUpDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalFollowUpDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalFollowUpDigest) {
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

        func list() -> [RegionalFollowUpDigest] {
            var out: [RegionalFollowUpDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalFollowUpDigestStore() -> any RegionalFollowUpDigestStore {
        return MemoryRegionalFollowUpDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalFollowUpDigestStore: RegionalFollowUpDigestStore {
        var inner: MemoryRegionalFollowUpDigestStore
        var cache: TTLCache<RegionalFollowUpDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalFollowUpDigestStore, cache: TTLCache<RegionalFollowUpDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalFollowUpDigest? {
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

        func save(_ item: RegionalFollowUpDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalFollowUpDigest] {
            return inner.list()
        }
    }

    static func newCachedRegionalFollowUpDigestStore(_ inner: MemoryRegionalFollowUpDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalFollowUpDigestStore {
        return CachedRegionalFollowUpDigestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional follow up digests. Empty fields match all.
    final class RegionalFollowUpDigestQuery {
        var title: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalFollowUpDigest) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [RegionalFollowUpDigest]) -> [RegionalFollowUpDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalFollowUpDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalFollowUpDigests(_ store: any RegionalFollowUpDigestStore, query: RegionalFollowUpDigestQuery) -> [RegionalFollowUpDigest] {
        return query.apply(store.list())
    }
}
