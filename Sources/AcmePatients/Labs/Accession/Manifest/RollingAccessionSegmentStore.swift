import AcmePlatform
import Foundation

extension Labs {
    /// Keeps rolling accession segments by code.
    protocol RollingAccessionSegmentStore {
        func find(_ code: String) -> RollingAccessionSegment?
        func save(_ item: RollingAccessionSegment)
        func remove(_ code: String) -> Bool
        func list() -> [RollingAccessionSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingAccessionSegmentStore: RollingAccessionSegmentStore {
        var items: [String: RollingAccessionSegment]
        var order: [String]

        init(items: [String: RollingAccessionSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingAccessionSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingAccessionSegment) {
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

        func list() -> [RollingAccessionSegment] {
            var out: [RollingAccessionSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingAccessionSegmentStore() -> any RollingAccessionSegmentStore {
        return MemoryRollingAccessionSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingAccessionSegmentStore: RollingAccessionSegmentStore {
        var inner: MemoryRollingAccessionSegmentStore
        var cache: TTLCache<RollingAccessionSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingAccessionSegmentStore, cache: TTLCache<RollingAccessionSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingAccessionSegment? {
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

        func save(_ item: RollingAccessionSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingAccessionSegment] {
            return inner.list()
        }
    }

    static func newCachedRollingAccessionSegmentStore(_ inner: MemoryRollingAccessionSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingAccessionSegmentStore {
        return CachedRollingAccessionSegmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling accession segments. Empty fields match all.
    final class RollingAccessionSegmentQuery {
        var ward: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minCopay: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingAccessionSegment) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingAccessionSegment]) -> [RollingAccessionSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingAccessionSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingAccessionSegments(_ store: any RollingAccessionSegmentStore, query: RollingAccessionSegmentQuery) -> [RollingAccessionSegment] {
        return query.apply(store.list())
    }
}
