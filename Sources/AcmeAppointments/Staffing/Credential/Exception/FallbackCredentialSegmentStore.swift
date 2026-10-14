import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps fallback credential segments by code.
    protocol FallbackCredentialSegmentStore {
        func find(_ code: String) -> FallbackCredentialSegment?
        func save(_ item: FallbackCredentialSegment)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackCredentialSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackCredentialSegmentStore: FallbackCredentialSegmentStore {
        var items: [String: FallbackCredentialSegment]
        var order: [String]

        init(items: [String: FallbackCredentialSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackCredentialSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackCredentialSegment) {
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

        func list() -> [FallbackCredentialSegment] {
            var out: [FallbackCredentialSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackCredentialSegmentStore() -> any FallbackCredentialSegmentStore {
        return MemoryFallbackCredentialSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackCredentialSegmentStore: FallbackCredentialSegmentStore {
        var inner: MemoryFallbackCredentialSegmentStore
        var cache: TTLCache<FallbackCredentialSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackCredentialSegmentStore, cache: TTLCache<FallbackCredentialSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackCredentialSegment? {
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

        func save(_ item: FallbackCredentialSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackCredentialSegment] {
            return inner.list()
        }
    }

    static func newCachedFallbackCredentialSegmentStore(_ inner: MemoryFallbackCredentialSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackCredentialSegmentStore {
        return CachedFallbackCredentialSegmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback credential segments. Empty fields match all.
    final class FallbackCredentialSegmentQuery {
        var title: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackCredentialSegment) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackCredentialSegment]) -> [FallbackCredentialSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackCredentialSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackCredentialSegments(_ store: any FallbackCredentialSegmentStore, query: FallbackCredentialSegmentQuery) -> [FallbackCredentialSegment] {
        return query.apply(store.list())
    }
}
