import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps formulary baselines by code.
    protocol FormularyBaselineStore {
        func find(_ code: String) -> FormularyBaseline?
        func save(_ item: FormularyBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [FormularyBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFormularyBaselineStore: FormularyBaselineStore {
        var items: [String: FormularyBaseline]
        var order: [String]

        init(items: [String: FormularyBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FormularyBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FormularyBaseline) {
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

        func list() -> [FormularyBaseline] {
            var out: [FormularyBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFormularyBaselineStore() -> any FormularyBaselineStore {
        return MemoryFormularyBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFormularyBaselineStore: FormularyBaselineStore {
        var inner: MemoryFormularyBaselineStore
        var cache: TTLCache<FormularyBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryFormularyBaselineStore, cache: TTLCache<FormularyBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FormularyBaseline? {
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

        func save(_ item: FormularyBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FormularyBaseline] {
            return inner.list()
        }
    }

    static func newCachedFormularyBaselineStore(_ inner: MemoryFormularyBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FormularyBaselineStore {
        return CachedFormularyBaselineStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects formulary baselines. Empty fields match all.
    final class FormularyBaselineQuery {
        var category: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FormularyBaseline) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FormularyBaseline]) -> [FormularyBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FormularyBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFormularyBaselines(_ store: any FormularyBaselineStore, query: FormularyBaselineQuery) -> [FormularyBaseline] {
        return query.apply(store.list())
    }
}
