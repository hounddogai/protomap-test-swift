import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps isolation segments by code.
    protocol IsolationSegmentStore {
        func find(_ code: String) -> IsolationSegment?
        func save(_ item: IsolationSegment)
        func remove(_ code: String) -> Bool
        func list() -> [IsolationSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryIsolationSegmentStore: IsolationSegmentStore {
        var items: [String: IsolationSegment]
        var order: [String]

        init(items: [String: IsolationSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> IsolationSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: IsolationSegment) {
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

        func list() -> [IsolationSegment] {
            var out: [IsolationSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryIsolationSegmentStore() -> any IsolationSegmentStore {
        return MemoryIsolationSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedIsolationSegmentStore: IsolationSegmentStore {
        var inner: MemoryIsolationSegmentStore
        var cache: TTLCache<IsolationSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryIsolationSegmentStore, cache: TTLCache<IsolationSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> IsolationSegment? {
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

        func save(_ item: IsolationSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [IsolationSegment] {
            return inner.list()
        }
    }

    static func newCachedIsolationSegmentStore(_ inner: MemoryIsolationSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any IsolationSegmentStore {
        return CachedIsolationSegmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects isolation segments. Empty fields match all.
    final class IsolationSegmentQuery {
        var country: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: IsolationSegment) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [IsolationSegment]) -> [IsolationSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: IsolationSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findIsolationSegments(_ store: any IsolationSegmentStore, query: IsolationSegmentQuery) -> [IsolationSegment] {
        return query.apply(store.list())
    }
}
