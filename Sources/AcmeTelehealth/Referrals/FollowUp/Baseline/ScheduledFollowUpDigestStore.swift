import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps scheduled follow up digests by code.
    protocol ScheduledFollowUpDigestStore {
        func find(_ code: String) -> ScheduledFollowUpDigest?
        func save(_ item: ScheduledFollowUpDigest)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledFollowUpDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledFollowUpDigestStore: ScheduledFollowUpDigestStore {
        var items: [String: ScheduledFollowUpDigest]
        var order: [String]

        init(items: [String: ScheduledFollowUpDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledFollowUpDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledFollowUpDigest) {
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

        func list() -> [ScheduledFollowUpDigest] {
            var out: [ScheduledFollowUpDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledFollowUpDigestStore() -> any ScheduledFollowUpDigestStore {
        return MemoryScheduledFollowUpDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledFollowUpDigestStore: ScheduledFollowUpDigestStore {
        var inner: MemoryScheduledFollowUpDigestStore
        var cache: TTLCache<ScheduledFollowUpDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledFollowUpDigestStore, cache: TTLCache<ScheduledFollowUpDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledFollowUpDigest? {
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

        func save(_ item: ScheduledFollowUpDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledFollowUpDigest] {
            return inner.list()
        }
    }

    static func newCachedScheduledFollowUpDigestStore(_ inner: MemoryScheduledFollowUpDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledFollowUpDigestStore {
        return CachedScheduledFollowUpDigestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled follow up digests. Empty fields match all.
    final class ScheduledFollowUpDigestQuery {
        var locale: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledFollowUpDigest) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledFollowUpDigest]) -> [ScheduledFollowUpDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledFollowUpDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledFollowUpDigests(_ store: any ScheduledFollowUpDigestStore, query: ScheduledFollowUpDigestQuery) -> [ScheduledFollowUpDigest] {
        return query.apply(store.list())
    }
}
