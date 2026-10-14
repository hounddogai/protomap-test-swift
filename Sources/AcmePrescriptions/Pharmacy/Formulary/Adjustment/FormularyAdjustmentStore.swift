import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps formulary adjustments by code.
    protocol FormularyAdjustmentStore {
        func find(_ code: String) -> FormularyAdjustment?
        func save(_ item: FormularyAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [FormularyAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFormularyAdjustmentStore: FormularyAdjustmentStore {
        var items: [String: FormularyAdjustment]
        var order: [String]

        init(items: [String: FormularyAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FormularyAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FormularyAdjustment) {
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

        func list() -> [FormularyAdjustment] {
            var out: [FormularyAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFormularyAdjustmentStore() -> any FormularyAdjustmentStore {
        return MemoryFormularyAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFormularyAdjustmentStore: FormularyAdjustmentStore {
        var inner: MemoryFormularyAdjustmentStore
        var cache: TTLCache<FormularyAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryFormularyAdjustmentStore, cache: TTLCache<FormularyAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FormularyAdjustment? {
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

        func save(_ item: FormularyAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FormularyAdjustment] {
            return inner.list()
        }
    }

    static func newCachedFormularyAdjustmentStore(_ inner: MemoryFormularyAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FormularyAdjustmentStore {
        return CachedFormularyAdjustmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects formulary adjustments. Empty fields match all.
    final class FormularyAdjustmentQuery {
        var locale: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FormularyAdjustment) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FormularyAdjustment]) -> [FormularyAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FormularyAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFormularyAdjustments(_ store: any FormularyAdjustmentStore, query: FormularyAdjustmentQuery) -> [FormularyAdjustment] {
        return query.apply(store.list())
    }
}
