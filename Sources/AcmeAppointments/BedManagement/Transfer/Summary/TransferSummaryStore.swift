import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps transfer summaries by code.
    protocol TransferSummaryStore {
        func find(_ code: String) -> TransferSummary?
        func save(_ item: TransferSummary)
        func remove(_ code: String) -> Bool
        func list() -> [TransferSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTransferSummaryStore: TransferSummaryStore {
        var items: [String: TransferSummary]
        var order: [String]

        init(items: [String: TransferSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TransferSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TransferSummary) {
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

        func list() -> [TransferSummary] {
            var out: [TransferSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTransferSummaryStore() -> any TransferSummaryStore {
        return MemoryTransferSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTransferSummaryStore: TransferSummaryStore {
        var inner: MemoryTransferSummaryStore
        var cache: TTLCache<TransferSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryTransferSummaryStore, cache: TTLCache<TransferSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TransferSummary? {
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

        func save(_ item: TransferSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TransferSummary] {
            return inner.list()
        }
    }

    static func newCachedTransferSummaryStore(_ inner: MemoryTransferSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TransferSummaryStore {
        return CachedTransferSummaryStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects transfer summaries. Empty fields match all.
    final class TransferSummaryQuery {
        var title: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TransferSummary) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TransferSummary]) -> [TransferSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TransferSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTransferSummaries(_ store: any TransferSummaryStore, query: TransferSummaryQuery) -> [TransferSummary] {
        return query.apply(store.list())
    }
}
