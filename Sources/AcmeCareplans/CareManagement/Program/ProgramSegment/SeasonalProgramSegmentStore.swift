import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps seasonal program segments by code.
    protocol SeasonalProgramSegmentStore {
        func find(_ code: String) -> SeasonalProgramSegment?
        func save(_ item: SeasonalProgramSegment)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalProgramSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalProgramSegmentStore: SeasonalProgramSegmentStore {
        var items: [String: SeasonalProgramSegment]
        var order: [String]

        init(items: [String: SeasonalProgramSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalProgramSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalProgramSegment) {
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

        func list() -> [SeasonalProgramSegment] {
            var out: [SeasonalProgramSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalProgramSegmentStore() -> any SeasonalProgramSegmentStore {
        return MemorySeasonalProgramSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalProgramSegmentStore: SeasonalProgramSegmentStore {
        var inner: MemorySeasonalProgramSegmentStore
        var cache: TTLCache<SeasonalProgramSegment>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalProgramSegmentStore, cache: TTLCache<SeasonalProgramSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalProgramSegment? {
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

        func save(_ item: SeasonalProgramSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalProgramSegment] {
            return inner.list()
        }
    }

    static func newCachedSeasonalProgramSegmentStore(_ inner: MemorySeasonalProgramSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalProgramSegmentStore {
        return CachedSeasonalProgramSegmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal program segments. Empty fields match all.
    final class SeasonalProgramSegmentQuery {
        var segment: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minWeight: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalProgramSegment) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalProgramSegment]) -> [SeasonalProgramSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalProgramSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalProgramSegments(_ store: any SeasonalProgramSegmentStore, query: SeasonalProgramSegmentQuery) -> [SeasonalProgramSegment] {
        return query.apply(store.list())
    }
}
