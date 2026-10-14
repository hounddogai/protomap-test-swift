import AcmePlatform
import Foundation

extension Consent {
    /// Keeps seasonal witness digests by code.
    protocol SeasonalWitnessDigestStore {
        func find(_ code: String) -> SeasonalWitnessDigest?
        func save(_ item: SeasonalWitnessDigest)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalWitnessDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalWitnessDigestStore: SeasonalWitnessDigestStore {
        var items: [String: SeasonalWitnessDigest]
        var order: [String]

        init(items: [String: SeasonalWitnessDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalWitnessDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalWitnessDigest) {
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

        func list() -> [SeasonalWitnessDigest] {
            var out: [SeasonalWitnessDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalWitnessDigestStore() -> any SeasonalWitnessDigestStore {
        return MemorySeasonalWitnessDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalWitnessDigestStore: SeasonalWitnessDigestStore {
        var inner: MemorySeasonalWitnessDigestStore
        var cache: TTLCache<SeasonalWitnessDigest>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalWitnessDigestStore, cache: TTLCache<SeasonalWitnessDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalWitnessDigest? {
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

        func save(_ item: SeasonalWitnessDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalWitnessDigest] {
            return inner.list()
        }
    }

    static func newCachedSeasonalWitnessDigestStore(_ inner: MemorySeasonalWitnessDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalWitnessDigestStore {
        return CachedSeasonalWitnessDigestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal witness digests. Empty fields match all.
    final class SeasonalWitnessDigestQuery {
        var unit: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minRatio: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalWitnessDigest) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalWitnessDigest]) -> [SeasonalWitnessDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalWitnessDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalWitnessDigests(_ store: any SeasonalWitnessDigestStore, query: SeasonalWitnessDigestQuery) -> [SeasonalWitnessDigest] {
        return query.apply(store.list())
    }
}
