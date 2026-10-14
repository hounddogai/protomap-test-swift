import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps pending worklist summaries by code.
    protocol PendingWorklistSummaryStore {
        func find(_ code: String) -> PendingWorklistSummary?
        func save(_ item: PendingWorklistSummary)
        func remove(_ code: String) -> Bool
        func list() -> [PendingWorklistSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingWorklistSummaryStore: PendingWorklistSummaryStore {
        var items: [String: PendingWorklistSummary]
        var order: [String]

        init(items: [String: PendingWorklistSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingWorklistSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingWorklistSummary) {
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

        func list() -> [PendingWorklistSummary] {
            var out: [PendingWorklistSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingWorklistSummaryStore() -> any PendingWorklistSummaryStore {
        return MemoryPendingWorklistSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingWorklistSummaryStore: PendingWorklistSummaryStore {
        var inner: MemoryPendingWorklistSummaryStore
        var cache: TTLCache<PendingWorklistSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingWorklistSummaryStore, cache: TTLCache<PendingWorklistSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingWorklistSummary? {
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

        func save(_ item: PendingWorklistSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingWorklistSummary] {
            return inner.list()
        }
    }

    static func newCachedPendingWorklistSummaryStore(_ inner: MemoryPendingWorklistSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingWorklistSummaryStore {
        return CachedPendingWorklistSummaryStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending worklist summaries. Empty fields match all.
    final class PendingWorklistSummaryQuery {
        var label: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minSequence: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingWorklistSummary) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingWorklistSummary]) -> [PendingWorklistSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingWorklistSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingWorklistSummaries(_ store: any PendingWorklistSummaryStore, query: PendingWorklistSummaryQuery) -> [PendingWorklistSummary] {
        return query.apply(store.list())
    }
}
