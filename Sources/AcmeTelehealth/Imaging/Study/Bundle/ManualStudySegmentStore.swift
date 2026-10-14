import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps manual study segments by code.
    protocol ManualStudySegmentStore {
        func find(_ code: String) -> ManualStudySegment?
        func save(_ item: ManualStudySegment)
        func remove(_ code: String) -> Bool
        func list() -> [ManualStudySegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualStudySegmentStore: ManualStudySegmentStore {
        var items: [String: ManualStudySegment]
        var order: [String]

        init(items: [String: ManualStudySegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualStudySegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualStudySegment) {
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

        func list() -> [ManualStudySegment] {
            var out: [ManualStudySegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualStudySegmentStore() -> any ManualStudySegmentStore {
        return MemoryManualStudySegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualStudySegmentStore: ManualStudySegmentStore {
        var inner: MemoryManualStudySegmentStore
        var cache: TTLCache<ManualStudySegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualStudySegmentStore, cache: TTLCache<ManualStudySegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualStudySegment? {
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

        func save(_ item: ManualStudySegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualStudySegment] {
            return inner.list()
        }
    }

    static func newCachedManualStudySegmentStore(_ inner: MemoryManualStudySegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualStudySegmentStore {
        return CachedManualStudySegmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual study segments. Empty fields match all.
    final class ManualStudySegmentQuery {
        var country: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualStudySegment) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualStudySegment]) -> [ManualStudySegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualStudySegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualStudySegments(_ store: any ManualStudySegmentStore, query: ManualStudySegmentQuery) -> [ManualStudySegment] {
        return query.apply(store.list())
    }
}
