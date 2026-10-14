import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps seasonal skill mix segments by code.
    protocol SeasonalSkillMixSegmentStore {
        func find(_ code: String) -> SeasonalSkillMixSegment?
        func save(_ item: SeasonalSkillMixSegment)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalSkillMixSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalSkillMixSegmentStore: SeasonalSkillMixSegmentStore {
        var items: [String: SeasonalSkillMixSegment]
        var order: [String]

        init(items: [String: SeasonalSkillMixSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalSkillMixSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalSkillMixSegment) {
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

        func list() -> [SeasonalSkillMixSegment] {
            var out: [SeasonalSkillMixSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalSkillMixSegmentStore() -> any SeasonalSkillMixSegmentStore {
        return MemorySeasonalSkillMixSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalSkillMixSegmentStore: SeasonalSkillMixSegmentStore {
        var inner: MemorySeasonalSkillMixSegmentStore
        var cache: TTLCache<SeasonalSkillMixSegment>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalSkillMixSegmentStore, cache: TTLCache<SeasonalSkillMixSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalSkillMixSegment? {
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

        func save(_ item: SeasonalSkillMixSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalSkillMixSegment] {
            return inner.list()
        }
    }

    static func newCachedSeasonalSkillMixSegmentStore(_ inner: MemorySeasonalSkillMixSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalSkillMixSegmentStore {
        return CachedSeasonalSkillMixSegmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal skill mix segments. Empty fields match all.
    final class SeasonalSkillMixSegmentQuery {
        var category: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalSkillMixSegment) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalSkillMixSegment]) -> [SeasonalSkillMixSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalSkillMixSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalSkillMixSegments(_ store: any SeasonalSkillMixSegmentStore, query: SeasonalSkillMixSegmentQuery) -> [SeasonalSkillMixSegment] {
        return query.apply(store.list())
    }
}
