import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps transfer estimates by code.
    protocol TransferEstimateStore {
        func find(_ code: String) -> TransferEstimate?
        func save(_ item: TransferEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [TransferEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTransferEstimateStore: TransferEstimateStore {
        var items: [String: TransferEstimate]
        var order: [String]

        init(items: [String: TransferEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TransferEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TransferEstimate) {
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

        func list() -> [TransferEstimate] {
            var out: [TransferEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTransferEstimateStore() -> any TransferEstimateStore {
        return MemoryTransferEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTransferEstimateStore: TransferEstimateStore {
        var inner: MemoryTransferEstimateStore
        var cache: TTLCache<TransferEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryTransferEstimateStore, cache: TTLCache<TransferEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TransferEstimate? {
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

        func save(_ item: TransferEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TransferEstimate] {
            return inner.list()
        }
    }

    static func newCachedTransferEstimateStore(_ inner: MemoryTransferEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TransferEstimateStore {
        return CachedTransferEstimateStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects transfer estimates. Empty fields match all.
    final class TransferEstimateQuery {
        var locale: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minBudget: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TransferEstimate) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TransferEstimate]) -> [TransferEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TransferEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTransferEstimates(_ store: any TransferEstimateStore, query: TransferEstimateQuery) -> [TransferEstimate] {
        return query.apply(store.list())
    }
}
