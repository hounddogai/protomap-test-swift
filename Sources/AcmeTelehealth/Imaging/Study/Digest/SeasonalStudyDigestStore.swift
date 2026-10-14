import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps seasonal study digests by code.
    protocol SeasonalStudyDigestStore {
        func find(_ code: String) -> SeasonalStudyDigest?
        func save(_ item: SeasonalStudyDigest)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalStudyDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalStudyDigestStore: SeasonalStudyDigestStore {
        var items: [String: SeasonalStudyDigest]
        var order: [String]

        init(items: [String: SeasonalStudyDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalStudyDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalStudyDigest) {
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

        func list() -> [SeasonalStudyDigest] {
            var out: [SeasonalStudyDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalStudyDigestStore() -> any SeasonalStudyDigestStore {
        return MemorySeasonalStudyDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalStudyDigestStore: SeasonalStudyDigestStore {
        var inner: MemorySeasonalStudyDigestStore
        var cache: TTLCache<SeasonalStudyDigest>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalStudyDigestStore, cache: TTLCache<SeasonalStudyDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalStudyDigest? {
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

        func save(_ item: SeasonalStudyDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalStudyDigest] {
            return inner.list()
        }
    }

    static func newCachedSeasonalStudyDigestStore(_ inner: MemorySeasonalStudyDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalStudyDigestStore {
        return CachedSeasonalStudyDigestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal study digests. Empty fields match all.
    final class SeasonalStudyDigestQuery {
        var label: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minRate: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalStudyDigest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalStudyDigest]) -> [SeasonalStudyDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalStudyDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalStudyDigests(_ store: any SeasonalStudyDigestStore, query: SeasonalStudyDigestQuery) -> [SeasonalStudyDigest] {
        return query.apply(store.list())
    }
}
