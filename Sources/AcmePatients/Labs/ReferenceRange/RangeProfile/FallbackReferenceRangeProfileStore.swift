import AcmePlatform
import Foundation

extension Labs {
    /// Keeps fallback reference range profiles by code.
    protocol FallbackReferenceRangeProfileStore {
        func find(_ code: String) -> FallbackReferenceRangeProfile?
        func save(_ item: FallbackReferenceRangeProfile)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackReferenceRangeProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackReferenceRangeProfileStore: FallbackReferenceRangeProfileStore {
        var items: [String: FallbackReferenceRangeProfile]
        var order: [String]

        init(items: [String: FallbackReferenceRangeProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackReferenceRangeProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackReferenceRangeProfile) {
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

        func list() -> [FallbackReferenceRangeProfile] {
            var out: [FallbackReferenceRangeProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackReferenceRangeProfileStore() -> any FallbackReferenceRangeProfileStore {
        return MemoryFallbackReferenceRangeProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackReferenceRangeProfileStore: FallbackReferenceRangeProfileStore {
        var inner: MemoryFallbackReferenceRangeProfileStore
        var cache: TTLCache<FallbackReferenceRangeProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackReferenceRangeProfileStore, cache: TTLCache<FallbackReferenceRangeProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackReferenceRangeProfile? {
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

        func save(_ item: FallbackReferenceRangeProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackReferenceRangeProfile] {
            return inner.list()
        }
    }

    static func newCachedFallbackReferenceRangeProfileStore(_ inner: MemoryFallbackReferenceRangeProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackReferenceRangeProfileStore {
        return CachedFallbackReferenceRangeProfileStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback reference range profiles. Empty fields match all.
    final class FallbackReferenceRangeProfileQuery {
        var segment: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minMargin: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackReferenceRangeProfile) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [FallbackReferenceRangeProfile]) -> [FallbackReferenceRangeProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackReferenceRangeProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackReferenceRangeProfiles(_ store: any FallbackReferenceRangeProfileStore, query: FallbackReferenceRangeProfileQuery) -> [FallbackReferenceRangeProfile] {
        return query.apply(store.list())
    }
}
