import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps alert batches by code.
    protocol AlertBatchStore {
        func find(_ code: String) -> AlertBatch?
        func save(_ item: AlertBatch)
        func remove(_ code: String) -> Bool
        func list() -> [AlertBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAlertBatchStore: AlertBatchStore {
        var items: [String: AlertBatch]
        var order: [String]

        init(items: [String: AlertBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AlertBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AlertBatch) {
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

        func list() -> [AlertBatch] {
            var out: [AlertBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAlertBatchStore() -> any AlertBatchStore {
        return MemoryAlertBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAlertBatchStore: AlertBatchStore {
        var inner: MemoryAlertBatchStore
        var cache: TTLCache<AlertBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryAlertBatchStore, cache: TTLCache<AlertBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AlertBatch? {
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

        func save(_ item: AlertBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AlertBatch] {
            return inner.list()
        }
    }

    static func newCachedAlertBatchStore(_ inner: MemoryAlertBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AlertBatchStore {
        return CachedAlertBatchStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects alert batches. Empty fields match all.
    final class AlertBatchQuery {
        var locale: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AlertBatch) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [AlertBatch]) -> [AlertBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AlertBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAlertBatches(_ store: any AlertBatchStore, query: AlertBatchQuery) -> [AlertBatch] {
        return query.apply(store.list())
    }
}
