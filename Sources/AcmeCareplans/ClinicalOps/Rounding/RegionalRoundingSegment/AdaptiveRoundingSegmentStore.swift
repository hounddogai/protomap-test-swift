import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps adaptive rounding segments by code.
    protocol AdaptiveRoundingSegmentStore {
        func find(_ code: String) -> AdaptiveRoundingSegment?
        func save(_ item: AdaptiveRoundingSegment)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveRoundingSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveRoundingSegmentStore: AdaptiveRoundingSegmentStore {
        var items: [String: AdaptiveRoundingSegment]
        var order: [String]

        init(items: [String: AdaptiveRoundingSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveRoundingSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveRoundingSegment) {
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

        func list() -> [AdaptiveRoundingSegment] {
            var out: [AdaptiveRoundingSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveRoundingSegmentStore() -> any AdaptiveRoundingSegmentStore {
        return MemoryAdaptiveRoundingSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveRoundingSegmentStore: AdaptiveRoundingSegmentStore {
        var inner: MemoryAdaptiveRoundingSegmentStore
        var cache: TTLCache<AdaptiveRoundingSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveRoundingSegmentStore, cache: TTLCache<AdaptiveRoundingSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveRoundingSegment? {
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

        func save(_ item: AdaptiveRoundingSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveRoundingSegment] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveRoundingSegmentStore(_ inner: MemoryAdaptiveRoundingSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveRoundingSegmentStore {
        return CachedAdaptiveRoundingSegmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive rounding segments. Empty fields match all.
    final class AdaptiveRoundingSegmentQuery {
        var name: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveRoundingSegment) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveRoundingSegment]) -> [AdaptiveRoundingSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveRoundingSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveRoundingSegments(_ store: any AdaptiveRoundingSegmentStore, query: AdaptiveRoundingSegmentQuery) -> [AdaptiveRoundingSegment] {
        return query.apply(store.list())
    }
}
