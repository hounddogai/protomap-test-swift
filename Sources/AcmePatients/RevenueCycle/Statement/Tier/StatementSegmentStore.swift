import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps statement segments by code.
    protocol StatementSegmentStore {
        func find(_ code: String) -> StatementSegment?
        func save(_ item: StatementSegment)
        func remove(_ code: String) -> Bool
        func list() -> [StatementSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStatementSegmentStore: StatementSegmentStore {
        var items: [String: StatementSegment]
        var order: [String]

        init(items: [String: StatementSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StatementSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StatementSegment) {
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

        func list() -> [StatementSegment] {
            var out: [StatementSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStatementSegmentStore() -> any StatementSegmentStore {
        return MemoryStatementSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStatementSegmentStore: StatementSegmentStore {
        var inner: MemoryStatementSegmentStore
        var cache: TTLCache<StatementSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryStatementSegmentStore, cache: TTLCache<StatementSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StatementSegment? {
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

        func save(_ item: StatementSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StatementSegment] {
            return inner.list()
        }
    }

    static func newCachedStatementSegmentStore(_ inner: MemoryStatementSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StatementSegmentStore {
        return CachedStatementSegmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects statement segments. Empty fields match all.
    final class StatementSegmentQuery {
        var ward: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StatementSegment) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StatementSegment]) -> [StatementSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StatementSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStatementSegments(_ store: any StatementSegmentStore, query: StatementSegmentQuery) -> [StatementSegment] {
        return query.apply(store.list())
    }
}
