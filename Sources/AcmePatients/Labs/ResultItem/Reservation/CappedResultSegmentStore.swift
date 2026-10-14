import AcmePlatform
import Foundation

extension Labs {
    /// Keeps capped result segments by code.
    protocol CappedResultSegmentStore {
        func find(_ code: String) -> CappedResultSegment?
        func save(_ item: CappedResultSegment)
        func remove(_ code: String) -> Bool
        func list() -> [CappedResultSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedResultSegmentStore: CappedResultSegmentStore {
        var items: [String: CappedResultSegment]
        var order: [String]

        init(items: [String: CappedResultSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedResultSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedResultSegment) {
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

        func list() -> [CappedResultSegment] {
            var out: [CappedResultSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedResultSegmentStore() -> any CappedResultSegmentStore {
        return MemoryCappedResultSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedResultSegmentStore: CappedResultSegmentStore {
        var inner: MemoryCappedResultSegmentStore
        var cache: TTLCache<CappedResultSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedResultSegmentStore, cache: TTLCache<CappedResultSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedResultSegment? {
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

        func save(_ item: CappedResultSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedResultSegment] {
            return inner.list()
        }
    }

    static func newCachedCappedResultSegmentStore(_ inner: MemoryCappedResultSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedResultSegmentStore {
        return CachedCappedResultSegmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped result segments. Empty fields match all.
    final class CappedResultSegmentQuery {
        var facility: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedResultSegment) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedResultSegment]) -> [CappedResultSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedResultSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedResultSegments(_ store: any CappedResultSegmentStore, query: CappedResultSegmentQuery) -> [CappedResultSegment] {
        return query.apply(store.list())
    }
}
