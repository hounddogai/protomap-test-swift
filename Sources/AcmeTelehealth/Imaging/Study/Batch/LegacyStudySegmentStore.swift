import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps legacy study segments by code.
    protocol LegacyStudySegmentStore {
        func find(_ code: String) -> LegacyStudySegment?
        func save(_ item: LegacyStudySegment)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyStudySegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyStudySegmentStore: LegacyStudySegmentStore {
        var items: [String: LegacyStudySegment]
        var order: [String]

        init(items: [String: LegacyStudySegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyStudySegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyStudySegment) {
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

        func list() -> [LegacyStudySegment] {
            var out: [LegacyStudySegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyStudySegmentStore() -> any LegacyStudySegmentStore {
        return MemoryLegacyStudySegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyStudySegmentStore: LegacyStudySegmentStore {
        var inner: MemoryLegacyStudySegmentStore
        var cache: TTLCache<LegacyStudySegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyStudySegmentStore, cache: TTLCache<LegacyStudySegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyStudySegment? {
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

        func save(_ item: LegacyStudySegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyStudySegment] {
            return inner.list()
        }
    }

    static func newCachedLegacyStudySegmentStore(_ inner: MemoryLegacyStudySegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyStudySegmentStore {
        return CachedLegacyStudySegmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy study segments. Empty fields match all.
    final class LegacyStudySegmentQuery {
        var label: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyStudySegment) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [LegacyStudySegment]) -> [LegacyStudySegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyStudySegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyStudySegments(_ store: any LegacyStudySegmentStore, query: LegacyStudySegmentQuery) -> [LegacyStudySegment] {
        return query.apply(store.list())
    }
}
