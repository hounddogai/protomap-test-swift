import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps claim segments by code.
    protocol ClaimSegmentStore {
        func find(_ code: String) -> ClaimSegment?
        func save(_ item: ClaimSegment)
        func remove(_ code: String) -> Bool
        func list() -> [ClaimSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClaimSegmentStore: ClaimSegmentStore {
        var items: [String: ClaimSegment]
        var order: [String]

        init(items: [String: ClaimSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClaimSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClaimSegment) {
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

        func list() -> [ClaimSegment] {
            var out: [ClaimSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClaimSegmentStore() -> any ClaimSegmentStore {
        return MemoryClaimSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClaimSegmentStore: ClaimSegmentStore {
        var inner: MemoryClaimSegmentStore
        var cache: TTLCache<ClaimSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryClaimSegmentStore, cache: TTLCache<ClaimSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClaimSegment? {
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

        func save(_ item: ClaimSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClaimSegment] {
            return inner.list()
        }
    }

    static func newCachedClaimSegmentStore(_ inner: MemoryClaimSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClaimSegmentStore {
        return CachedClaimSegmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects claim segments. Empty fields match all.
    final class ClaimSegmentQuery {
        var label: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClaimSegment) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ClaimSegment]) -> [ClaimSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClaimSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClaimSegments(_ store: any ClaimSegmentStore, query: ClaimSegmentQuery) -> [ClaimSegment] {
        return query.apply(store.list())
    }
}
