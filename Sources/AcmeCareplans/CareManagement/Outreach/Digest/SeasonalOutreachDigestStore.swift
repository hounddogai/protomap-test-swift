import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps seasonal outreach digests by code.
    protocol SeasonalOutreachDigestStore {
        func find(_ code: String) -> SeasonalOutreachDigest?
        func save(_ item: SeasonalOutreachDigest)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalOutreachDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalOutreachDigestStore: SeasonalOutreachDigestStore {
        var items: [String: SeasonalOutreachDigest]
        var order: [String]

        init(items: [String: SeasonalOutreachDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalOutreachDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalOutreachDigest) {
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

        func list() -> [SeasonalOutreachDigest] {
            var out: [SeasonalOutreachDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalOutreachDigestStore() -> any SeasonalOutreachDigestStore {
        return MemorySeasonalOutreachDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalOutreachDigestStore: SeasonalOutreachDigestStore {
        var inner: MemorySeasonalOutreachDigestStore
        var cache: TTLCache<SeasonalOutreachDigest>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalOutreachDigestStore, cache: TTLCache<SeasonalOutreachDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalOutreachDigest? {
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

        func save(_ item: SeasonalOutreachDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalOutreachDigest] {
            return inner.list()
        }
    }

    static func newCachedSeasonalOutreachDigestStore(_ inner: MemorySeasonalOutreachDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalOutreachDigestStore {
        return CachedSeasonalOutreachDigestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal outreach digests. Empty fields match all.
    final class SeasonalOutreachDigestQuery {
        var name: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMargin: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalOutreachDigest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalOutreachDigest]) -> [SeasonalOutreachDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalOutreachDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalOutreachDigests(_ store: any SeasonalOutreachDigestStore, query: SeasonalOutreachDigestQuery) -> [SeasonalOutreachDigest] {
        return query.apply(store.list())
    }
}
