import AcmePlatform
import Foundation

extension Labs {
    /// Keeps accession segments by code.
    protocol AccessionSegmentStore {
        func find(_ code: String) -> AccessionSegment?
        func save(_ item: AccessionSegment)
        func remove(_ code: String) -> Bool
        func list() -> [AccessionSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAccessionSegmentStore: AccessionSegmentStore {
        var items: [String: AccessionSegment]
        var order: [String]

        init(items: [String: AccessionSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AccessionSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AccessionSegment) {
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

        func list() -> [AccessionSegment] {
            var out: [AccessionSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAccessionSegmentStore() -> any AccessionSegmentStore {
        return MemoryAccessionSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAccessionSegmentStore: AccessionSegmentStore {
        var inner: MemoryAccessionSegmentStore
        var cache: TTLCache<AccessionSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryAccessionSegmentStore, cache: TTLCache<AccessionSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AccessionSegment? {
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

        func save(_ item: AccessionSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AccessionSegment] {
            return inner.list()
        }
    }

    static func newCachedAccessionSegmentStore(_ inner: MemoryAccessionSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AccessionSegmentStore {
        return CachedAccessionSegmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects accession segments. Empty fields match all.
    final class AccessionSegmentQuery {
        var unit: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minScore: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AccessionSegment) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AccessionSegment]) -> [AccessionSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AccessionSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAccessionSegments(_ store: any AccessionSegmentStore, query: AccessionSegmentQuery) -> [AccessionSegment] {
        return query.apply(store.list())
    }
}
