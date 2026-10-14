import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps formulary batches by code.
    protocol FormularyBatchStore {
        func find(_ code: String) -> FormularyBatch?
        func save(_ item: FormularyBatch)
        func remove(_ code: String) -> Bool
        func list() -> [FormularyBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFormularyBatchStore: FormularyBatchStore {
        var items: [String: FormularyBatch]
        var order: [String]

        init(items: [String: FormularyBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FormularyBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FormularyBatch) {
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

        func list() -> [FormularyBatch] {
            var out: [FormularyBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFormularyBatchStore() -> any FormularyBatchStore {
        return MemoryFormularyBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFormularyBatchStore: FormularyBatchStore {
        var inner: MemoryFormularyBatchStore
        var cache: TTLCache<FormularyBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryFormularyBatchStore, cache: TTLCache<FormularyBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FormularyBatch? {
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

        func save(_ item: FormularyBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FormularyBatch] {
            return inner.list()
        }
    }

    static func newCachedFormularyBatchStore(_ inner: MemoryFormularyBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FormularyBatchStore {
        return CachedFormularyBatchStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects formulary batches. Empty fields match all.
    final class FormularyBatchQuery {
        var locale: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FormularyBatch) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FormularyBatch]) -> [FormularyBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FormularyBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFormularyBatches(_ store: any FormularyBatchStore, query: FormularyBatchQuery) -> [FormularyBatch] {
        return query.apply(store.list())
    }
}
