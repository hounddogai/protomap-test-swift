import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps formulary variances by code.
    protocol FormularyVarianceStore {
        func find(_ code: String) -> FormularyVariance?
        func save(_ item: FormularyVariance)
        func remove(_ code: String) -> Bool
        func list() -> [FormularyVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFormularyVarianceStore: FormularyVarianceStore {
        var items: [String: FormularyVariance]
        var order: [String]

        init(items: [String: FormularyVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FormularyVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FormularyVariance) {
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

        func list() -> [FormularyVariance] {
            var out: [FormularyVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFormularyVarianceStore() -> any FormularyVarianceStore {
        return MemoryFormularyVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFormularyVarianceStore: FormularyVarianceStore {
        var inner: MemoryFormularyVarianceStore
        var cache: TTLCache<FormularyVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryFormularyVarianceStore, cache: TTLCache<FormularyVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FormularyVariance? {
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

        func save(_ item: FormularyVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FormularyVariance] {
            return inner.list()
        }
    }

    static func newCachedFormularyVarianceStore(_ inner: MemoryFormularyVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FormularyVarianceStore {
        return CachedFormularyVarianceStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects formulary variances. Empty fields match all.
    final class FormularyVarianceQuery {
        var category: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minMargin: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FormularyVariance) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FormularyVariance]) -> [FormularyVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FormularyVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFormularyVariances(_ store: any FormularyVarianceStore, query: FormularyVarianceQuery) -> [FormularyVariance] {
        return query.apply(store.list())
    }
}
