import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps fallback eligibility digests by code.
    protocol FallbackEligibilityDigestStore {
        func find(_ code: String) -> FallbackEligibilityDigest?
        func save(_ item: FallbackEligibilityDigest)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackEligibilityDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackEligibilityDigestStore: FallbackEligibilityDigestStore {
        var items: [String: FallbackEligibilityDigest]
        var order: [String]

        init(items: [String: FallbackEligibilityDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackEligibilityDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackEligibilityDigest) {
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

        func list() -> [FallbackEligibilityDigest] {
            var out: [FallbackEligibilityDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackEligibilityDigestStore() -> any FallbackEligibilityDigestStore {
        return MemoryFallbackEligibilityDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackEligibilityDigestStore: FallbackEligibilityDigestStore {
        var inner: MemoryFallbackEligibilityDigestStore
        var cache: TTLCache<FallbackEligibilityDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackEligibilityDigestStore, cache: TTLCache<FallbackEligibilityDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackEligibilityDigest? {
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

        func save(_ item: FallbackEligibilityDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackEligibilityDigest] {
            return inner.list()
        }
    }

    static func newCachedFallbackEligibilityDigestStore(_ inner: MemoryFallbackEligibilityDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackEligibilityDigestStore {
        return CachedFallbackEligibilityDigestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback eligibility digests. Empty fields match all.
    final class FallbackEligibilityDigestQuery {
        var label: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minPriority: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackEligibilityDigest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackEligibilityDigest]) -> [FallbackEligibilityDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackEligibilityDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackEligibilityDigests(_ store: any FallbackEligibilityDigestStore, query: FallbackEligibilityDigestQuery) -> [FallbackEligibilityDigest] {
        return query.apply(store.list())
    }
}
