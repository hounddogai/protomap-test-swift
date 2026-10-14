import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps formulary overrides by code.
    protocol FormularyOverrideStore {
        func find(_ code: String) -> FormularyOverride?
        func save(_ item: FormularyOverride)
        func remove(_ code: String) -> Bool
        func list() -> [FormularyOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFormularyOverrideStore: FormularyOverrideStore {
        var items: [String: FormularyOverride]
        var order: [String]

        init(items: [String: FormularyOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FormularyOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FormularyOverride) {
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

        func list() -> [FormularyOverride] {
            var out: [FormularyOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFormularyOverrideStore() -> any FormularyOverrideStore {
        return MemoryFormularyOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFormularyOverrideStore: FormularyOverrideStore {
        var inner: MemoryFormularyOverrideStore
        var cache: TTLCache<FormularyOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryFormularyOverrideStore, cache: TTLCache<FormularyOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FormularyOverride? {
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

        func save(_ item: FormularyOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FormularyOverride] {
            return inner.list()
        }
    }

    static func newCachedFormularyOverrideStore(_ inner: MemoryFormularyOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FormularyOverrideStore {
        return CachedFormularyOverrideStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects formulary overrides. Empty fields match all.
    final class FormularyOverrideQuery {
        var source: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minRate: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FormularyOverride) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FormularyOverride]) -> [FormularyOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FormularyOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFormularyOverrides(_ store: any FormularyOverrideStore, query: FormularyOverrideQuery) -> [FormularyOverride] {
        return query.apply(store.list())
    }
}
