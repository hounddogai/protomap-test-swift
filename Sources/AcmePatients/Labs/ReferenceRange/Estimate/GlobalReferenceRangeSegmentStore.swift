import AcmePlatform
import Foundation

extension Labs {
    /// Keeps global reference range segments by code.
    protocol GlobalReferenceRangeSegmentStore {
        func find(_ code: String) -> GlobalReferenceRangeSegment?
        func save(_ item: GlobalReferenceRangeSegment)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalReferenceRangeSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalReferenceRangeSegmentStore: GlobalReferenceRangeSegmentStore {
        var items: [String: GlobalReferenceRangeSegment]
        var order: [String]

        init(items: [String: GlobalReferenceRangeSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalReferenceRangeSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalReferenceRangeSegment) {
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

        func list() -> [GlobalReferenceRangeSegment] {
            var out: [GlobalReferenceRangeSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalReferenceRangeSegmentStore() -> any GlobalReferenceRangeSegmentStore {
        return MemoryGlobalReferenceRangeSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalReferenceRangeSegmentStore: GlobalReferenceRangeSegmentStore {
        var inner: MemoryGlobalReferenceRangeSegmentStore
        var cache: TTLCache<GlobalReferenceRangeSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalReferenceRangeSegmentStore, cache: TTLCache<GlobalReferenceRangeSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalReferenceRangeSegment? {
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

        func save(_ item: GlobalReferenceRangeSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalReferenceRangeSegment] {
            return inner.list()
        }
    }

    static func newCachedGlobalReferenceRangeSegmentStore(_ inner: MemoryGlobalReferenceRangeSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalReferenceRangeSegmentStore {
        return CachedGlobalReferenceRangeSegmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global reference range segments. Empty fields match all.
    final class GlobalReferenceRangeSegmentQuery {
        var channel: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalReferenceRangeSegment) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [GlobalReferenceRangeSegment]) -> [GlobalReferenceRangeSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalReferenceRangeSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalReferenceRangeSegments(_ store: any GlobalReferenceRangeSegmentStore, query: GlobalReferenceRangeSegmentQuery) -> [GlobalReferenceRangeSegment] {
        return query.apply(store.list())
    }
}
