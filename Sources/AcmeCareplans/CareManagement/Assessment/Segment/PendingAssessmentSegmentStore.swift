import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps pending assessment segments by code.
    protocol PendingAssessmentSegmentStore {
        func find(_ code: String) -> PendingAssessmentSegment?
        func save(_ item: PendingAssessmentSegment)
        func remove(_ code: String) -> Bool
        func list() -> [PendingAssessmentSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingAssessmentSegmentStore: PendingAssessmentSegmentStore {
        var items: [String: PendingAssessmentSegment]
        var order: [String]

        init(items: [String: PendingAssessmentSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingAssessmentSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingAssessmentSegment) {
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

        func list() -> [PendingAssessmentSegment] {
            var out: [PendingAssessmentSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingAssessmentSegmentStore() -> any PendingAssessmentSegmentStore {
        return MemoryPendingAssessmentSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingAssessmentSegmentStore: PendingAssessmentSegmentStore {
        var inner: MemoryPendingAssessmentSegmentStore
        var cache: TTLCache<PendingAssessmentSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingAssessmentSegmentStore, cache: TTLCache<PendingAssessmentSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingAssessmentSegment? {
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

        func save(_ item: PendingAssessmentSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingAssessmentSegment] {
            return inner.list()
        }
    }

    static func newCachedPendingAssessmentSegmentStore(_ inner: MemoryPendingAssessmentSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingAssessmentSegmentStore {
        return CachedPendingAssessmentSegmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending assessment segments. Empty fields match all.
    final class PendingAssessmentSegmentQuery {
        var name: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingAssessmentSegment) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingAssessmentSegment]) -> [PendingAssessmentSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingAssessmentSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingAssessmentSegments(_ store: any PendingAssessmentSegmentStore, query: PendingAssessmentSegmentQuery) -> [PendingAssessmentSegment] {
        return query.apply(store.list())
    }
}
