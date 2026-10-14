import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps seasonal formulary segments by code.
    protocol SeasonalFormularySegmentStore {
        func find(_ code: String) -> SeasonalFormularySegment?
        func save(_ item: SeasonalFormularySegment)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalFormularySegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalFormularySegmentStore: SeasonalFormularySegmentStore {
        var items: [String: SeasonalFormularySegment]
        var order: [String]

        init(items: [String: SeasonalFormularySegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalFormularySegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalFormularySegment) {
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

        func list() -> [SeasonalFormularySegment] {
            var out: [SeasonalFormularySegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalFormularySegmentStore() -> any SeasonalFormularySegmentStore {
        return MemorySeasonalFormularySegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalFormularySegmentStore: SeasonalFormularySegmentStore {
        var inner: MemorySeasonalFormularySegmentStore
        var cache: TTLCache<SeasonalFormularySegment>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalFormularySegmentStore, cache: TTLCache<SeasonalFormularySegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalFormularySegment? {
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

        func save(_ item: SeasonalFormularySegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalFormularySegment] {
            return inner.list()
        }
    }

    static func newCachedSeasonalFormularySegmentStore(_ inner: MemorySeasonalFormularySegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalFormularySegmentStore {
        return CachedSeasonalFormularySegmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal formulary segments. Empty fields match all.
    final class SeasonalFormularySegmentQuery {
        var label: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalFormularySegment) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [SeasonalFormularySegment]) -> [SeasonalFormularySegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalFormularySegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalFormularySegments(_ store: any SeasonalFormularySegmentStore, query: SeasonalFormularySegmentQuery) -> [SeasonalFormularySegment] {
        return query.apply(store.list())
    }
}
