import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps transfer metrics by code.
    protocol TransferMetricStore {
        func find(_ code: String) -> TransferMetric?
        func save(_ item: TransferMetric)
        func remove(_ code: String) -> Bool
        func list() -> [TransferMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTransferMetricStore: TransferMetricStore {
        var items: [String: TransferMetric]
        var order: [String]

        init(items: [String: TransferMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TransferMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TransferMetric) {
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

        func list() -> [TransferMetric] {
            var out: [TransferMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTransferMetricStore() -> any TransferMetricStore {
        return MemoryTransferMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTransferMetricStore: TransferMetricStore {
        var inner: MemoryTransferMetricStore
        var cache: TTLCache<TransferMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryTransferMetricStore, cache: TTLCache<TransferMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TransferMetric? {
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

        func save(_ item: TransferMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TransferMetric] {
            return inner.list()
        }
    }

    static func newCachedTransferMetricStore(_ inner: MemoryTransferMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TransferMetricStore {
        return CachedTransferMetricStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects transfer metrics. Empty fields match all.
    final class TransferMetricQuery {
        var locale: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TransferMetric) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TransferMetric]) -> [TransferMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TransferMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTransferMetrics(_ store: any TransferMetricStore, query: TransferMetricQuery) -> [TransferMetric] {
        return query.apply(store.list())
    }
}
