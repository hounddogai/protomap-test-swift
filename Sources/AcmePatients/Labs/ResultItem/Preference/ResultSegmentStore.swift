import AcmePlatform
import Foundation

extension Labs {
    /// Keeps result segments by code.
    protocol ResultSegmentStore {
        func find(_ code: String) -> ResultSegment?
        func save(_ item: ResultSegment)
        func remove(_ code: String) -> Bool
        func list() -> [ResultSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryResultSegmentStore: ResultSegmentStore {
        var items: [String: ResultSegment]
        var order: [String]

        init(items: [String: ResultSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ResultSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ResultSegment) {
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

        func list() -> [ResultSegment] {
            var out: [ResultSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryResultSegmentStore() -> any ResultSegmentStore {
        return MemoryResultSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedResultSegmentStore: ResultSegmentStore {
        var inner: MemoryResultSegmentStore
        var cache: TTLCache<ResultSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryResultSegmentStore, cache: TTLCache<ResultSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ResultSegment? {
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

        func save(_ item: ResultSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ResultSegment] {
            return inner.list()
        }
    }

    static func newCachedResultSegmentStore(_ inner: MemoryResultSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ResultSegmentStore {
        return CachedResultSegmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects result segments. Empty fields match all.
    final class ResultSegmentQuery {
        var label: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMargin: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ResultSegment) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ResultSegment]) -> [ResultSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ResultSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findResultSegments(_ store: any ResultSegmentStore, query: ResultSegmentQuery) -> [ResultSegment] {
        return query.apply(store.list())
    }
}
