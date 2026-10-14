import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps formulary estimates by code.
    protocol FormularyEstimateStore {
        func find(_ code: String) -> FormularyEstimate?
        func save(_ item: FormularyEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [FormularyEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFormularyEstimateStore: FormularyEstimateStore {
        var items: [String: FormularyEstimate]
        var order: [String]

        init(items: [String: FormularyEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FormularyEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FormularyEstimate) {
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

        func list() -> [FormularyEstimate] {
            var out: [FormularyEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFormularyEstimateStore() -> any FormularyEstimateStore {
        return MemoryFormularyEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFormularyEstimateStore: FormularyEstimateStore {
        var inner: MemoryFormularyEstimateStore
        var cache: TTLCache<FormularyEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryFormularyEstimateStore, cache: TTLCache<FormularyEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FormularyEstimate? {
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

        func save(_ item: FormularyEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FormularyEstimate] {
            return inner.list()
        }
    }

    static func newCachedFormularyEstimateStore(_ inner: MemoryFormularyEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FormularyEstimateStore {
        return CachedFormularyEstimateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects formulary estimates. Empty fields match all.
    final class FormularyEstimateQuery {
        var locale: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FormularyEstimate) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FormularyEstimate]) -> [FormularyEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FormularyEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFormularyEstimates(_ store: any FormularyEstimateStore, query: FormularyEstimateQuery) -> [FormularyEstimate] {
        return query.apply(store.list())
    }
}
