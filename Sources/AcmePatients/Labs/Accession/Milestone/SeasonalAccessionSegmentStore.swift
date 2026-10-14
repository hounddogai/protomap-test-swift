import AcmePlatform
import Foundation

extension Labs {
    /// Keeps seasonal accession segments by code.
    protocol SeasonalAccessionSegmentStore {
        func find(_ code: String) -> SeasonalAccessionSegment?
        func save(_ item: SeasonalAccessionSegment)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalAccessionSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalAccessionSegmentStore: SeasonalAccessionSegmentStore {
        var items: [String: SeasonalAccessionSegment]
        var order: [String]

        init(items: [String: SeasonalAccessionSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalAccessionSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalAccessionSegment) {
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

        func list() -> [SeasonalAccessionSegment] {
            var out: [SeasonalAccessionSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalAccessionSegmentStore() -> any SeasonalAccessionSegmentStore {
        return MemorySeasonalAccessionSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalAccessionSegmentStore: SeasonalAccessionSegmentStore {
        var inner: MemorySeasonalAccessionSegmentStore
        var cache: TTLCache<SeasonalAccessionSegment>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalAccessionSegmentStore, cache: TTLCache<SeasonalAccessionSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalAccessionSegment? {
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

        func save(_ item: SeasonalAccessionSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalAccessionSegment] {
            return inner.list()
        }
    }

    static func newCachedSeasonalAccessionSegmentStore(_ inner: MemorySeasonalAccessionSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalAccessionSegmentStore {
        return CachedSeasonalAccessionSegmentStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal accession segments. Empty fields match all.
    final class SeasonalAccessionSegmentQuery {
        var label: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalAccessionSegment) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalAccessionSegment]) -> [SeasonalAccessionSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalAccessionSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalAccessionSegments(_ store: any SeasonalAccessionSegmentStore, query: SeasonalAccessionSegmentQuery) -> [SeasonalAccessionSegment] {
        return query.apply(store.list())
    }
}
