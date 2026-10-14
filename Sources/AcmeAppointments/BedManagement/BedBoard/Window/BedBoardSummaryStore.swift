import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps bed board summaries by code.
    protocol BedBoardSummaryStore {
        func find(_ code: String) -> BedBoardSummary?
        func save(_ item: BedBoardSummary)
        func remove(_ code: String) -> Bool
        func list() -> [BedBoardSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBedBoardSummaryStore: BedBoardSummaryStore {
        var items: [String: BedBoardSummary]
        var order: [String]

        init(items: [String: BedBoardSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BedBoardSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BedBoardSummary) {
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

        func list() -> [BedBoardSummary] {
            var out: [BedBoardSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBedBoardSummaryStore() -> any BedBoardSummaryStore {
        return MemoryBedBoardSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBedBoardSummaryStore: BedBoardSummaryStore {
        var inner: MemoryBedBoardSummaryStore
        var cache: TTLCache<BedBoardSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryBedBoardSummaryStore, cache: TTLCache<BedBoardSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BedBoardSummary? {
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

        func save(_ item: BedBoardSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BedBoardSummary] {
            return inner.list()
        }
    }

    static func newCachedBedBoardSummaryStore(_ inner: MemoryBedBoardSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BedBoardSummaryStore {
        return CachedBedBoardSummaryStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects bed board summaries. Empty fields match all.
    final class BedBoardSummaryQuery {
        var title: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BedBoardSummary) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BedBoardSummary]) -> [BedBoardSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BedBoardSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBedBoardSummaries(_ store: any BedBoardSummaryStore, query: BedBoardSummaryQuery) -> [BedBoardSummary] {
        return query.apply(store.list())
    }
}
