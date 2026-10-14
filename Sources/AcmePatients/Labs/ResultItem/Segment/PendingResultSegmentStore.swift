import AcmePlatform
import Foundation

extension Labs {
    /// Keeps pending result segments by code.
    protocol PendingResultSegmentStore {
        func find(_ code: String) -> PendingResultSegment?
        func save(_ item: PendingResultSegment)
        func remove(_ code: String) -> Bool
        func list() -> [PendingResultSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingResultSegmentStore: PendingResultSegmentStore {
        var items: [String: PendingResultSegment]
        var order: [String]

        init(items: [String: PendingResultSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingResultSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingResultSegment) {
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

        func list() -> [PendingResultSegment] {
            var out: [PendingResultSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingResultSegmentStore() -> any PendingResultSegmentStore {
        return MemoryPendingResultSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingResultSegmentStore: PendingResultSegmentStore {
        var inner: MemoryPendingResultSegmentStore
        var cache: TTLCache<PendingResultSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingResultSegmentStore, cache: TTLCache<PendingResultSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingResultSegment? {
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

        func save(_ item: PendingResultSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingResultSegment] {
            return inner.list()
        }
    }

    static func newCachedPendingResultSegmentStore(_ inner: MemoryPendingResultSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingResultSegmentStore {
        return CachedPendingResultSegmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending result segments. Empty fields match all.
    final class PendingResultSegmentQuery {
        var segment: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingResultSegment) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingResultSegment]) -> [PendingResultSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingResultSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingResultSegments(_ store: any PendingResultSegmentStore, query: PendingResultSegmentQuery) -> [PendingResultSegment] {
        return query.apply(store.list())
    }
}
