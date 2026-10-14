import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps shift summaries by code.
    protocol ShiftSummaryStore {
        func find(_ code: String) -> ShiftSummary?
        func save(_ item: ShiftSummary)
        func remove(_ code: String) -> Bool
        func list() -> [ShiftSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryShiftSummaryStore: ShiftSummaryStore {
        var items: [String: ShiftSummary]
        var order: [String]

        init(items: [String: ShiftSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ShiftSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ShiftSummary) {
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

        func list() -> [ShiftSummary] {
            var out: [ShiftSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryShiftSummaryStore() -> any ShiftSummaryStore {
        return MemoryShiftSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedShiftSummaryStore: ShiftSummaryStore {
        var inner: MemoryShiftSummaryStore
        var cache: TTLCache<ShiftSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryShiftSummaryStore, cache: TTLCache<ShiftSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ShiftSummary? {
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

        func save(_ item: ShiftSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ShiftSummary] {
            return inner.list()
        }
    }

    static func newCachedShiftSummaryStore(_ inner: MemoryShiftSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ShiftSummaryStore {
        return CachedShiftSummaryStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects shift summaries. Empty fields match all.
    final class ShiftSummaryQuery {
        var region: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ShiftSummary) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ShiftSummary]) -> [ShiftSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ShiftSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findShiftSummaries(_ store: any ShiftSummaryStore, query: ShiftSummaryQuery) -> [ShiftSummary] {
        return query.apply(store.list())
    }
}
