import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps strict rounding digests by code.
    protocol StrictRoundingDigestStore {
        func find(_ code: String) -> StrictRoundingDigest?
        func save(_ item: StrictRoundingDigest)
        func remove(_ code: String) -> Bool
        func list() -> [StrictRoundingDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictRoundingDigestStore: StrictRoundingDigestStore {
        var items: [String: StrictRoundingDigest]
        var order: [String]

        init(items: [String: StrictRoundingDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictRoundingDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictRoundingDigest) {
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

        func list() -> [StrictRoundingDigest] {
            var out: [StrictRoundingDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictRoundingDigestStore() -> any StrictRoundingDigestStore {
        return MemoryStrictRoundingDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictRoundingDigestStore: StrictRoundingDigestStore {
        var inner: MemoryStrictRoundingDigestStore
        var cache: TTLCache<StrictRoundingDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictRoundingDigestStore, cache: TTLCache<StrictRoundingDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictRoundingDigest? {
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

        func save(_ item: StrictRoundingDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictRoundingDigest] {
            return inner.list()
        }
    }

    static func newCachedStrictRoundingDigestStore(_ inner: MemoryStrictRoundingDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictRoundingDigestStore {
        return CachedStrictRoundingDigestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict rounding digests. Empty fields match all.
    final class StrictRoundingDigestQuery {
        var source: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictRoundingDigest) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictRoundingDigest]) -> [StrictRoundingDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictRoundingDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictRoundingDigests(_ store: any StrictRoundingDigestStore, query: StrictRoundingDigestQuery) -> [StrictRoundingDigest] {
        return query.apply(store.list())
    }
}
