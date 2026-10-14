import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps skill mix segments by code.
    protocol SkillMixSegmentStore {
        func find(_ code: String) -> SkillMixSegment?
        func save(_ item: SkillMixSegment)
        func remove(_ code: String) -> Bool
        func list() -> [SkillMixSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySkillMixSegmentStore: SkillMixSegmentStore {
        var items: [String: SkillMixSegment]
        var order: [String]

        init(items: [String: SkillMixSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SkillMixSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SkillMixSegment) {
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

        func list() -> [SkillMixSegment] {
            var out: [SkillMixSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySkillMixSegmentStore() -> any SkillMixSegmentStore {
        return MemorySkillMixSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSkillMixSegmentStore: SkillMixSegmentStore {
        var inner: MemorySkillMixSegmentStore
        var cache: TTLCache<SkillMixSegment>
        var hits: Int
        var misses: Int

        init(inner: MemorySkillMixSegmentStore, cache: TTLCache<SkillMixSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SkillMixSegment? {
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

        func save(_ item: SkillMixSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SkillMixSegment] {
            return inner.list()
        }
    }

    static func newCachedSkillMixSegmentStore(_ inner: MemorySkillMixSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SkillMixSegmentStore {
        return CachedSkillMixSegmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects skill mix segments. Empty fields match all.
    final class SkillMixSegmentQuery {
        var segment: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SkillMixSegment) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SkillMixSegment]) -> [SkillMixSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SkillMixSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSkillMixSegments(_ store: any SkillMixSegmentStore, query: SkillMixSegmentQuery) -> [SkillMixSegment] {
        return query.apply(store.list())
    }
}
