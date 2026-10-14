import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps rolling interaction segments by code.
    protocol RollingInteractionSegmentStore {
        func find(_ code: String) -> RollingInteractionSegment?
        func save(_ item: RollingInteractionSegment)
        func remove(_ code: String) -> Bool
        func list() -> [RollingInteractionSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingInteractionSegmentStore: RollingInteractionSegmentStore {
        var items: [String: RollingInteractionSegment]
        var order: [String]

        init(items: [String: RollingInteractionSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingInteractionSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingInteractionSegment) {
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

        func list() -> [RollingInteractionSegment] {
            var out: [RollingInteractionSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingInteractionSegmentStore() -> any RollingInteractionSegmentStore {
        return MemoryRollingInteractionSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingInteractionSegmentStore: RollingInteractionSegmentStore {
        var inner: MemoryRollingInteractionSegmentStore
        var cache: TTLCache<RollingInteractionSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingInteractionSegmentStore, cache: TTLCache<RollingInteractionSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingInteractionSegment? {
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

        func save(_ item: RollingInteractionSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingInteractionSegment] {
            return inner.list()
        }
    }

    static func newCachedRollingInteractionSegmentStore(_ inner: MemoryRollingInteractionSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingInteractionSegmentStore {
        return CachedRollingInteractionSegmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling interaction segments. Empty fields match all.
    final class RollingInteractionSegmentQuery {
        var label: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minWeight: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingInteractionSegment) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [RollingInteractionSegment]) -> [RollingInteractionSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingInteractionSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingInteractionSegments(_ store: any RollingInteractionSegmentStore, query: RollingInteractionSegmentQuery) -> [RollingInteractionSegment] {
        return query.apply(store.list())
    }
}
