import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps formulary rollups by code.
    protocol FormularyRollupStore {
        func find(_ code: String) -> FormularyRollup?
        func save(_ item: FormularyRollup)
        func remove(_ code: String) -> Bool
        func list() -> [FormularyRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFormularyRollupStore: FormularyRollupStore {
        var items: [String: FormularyRollup]
        var order: [String]

        init(items: [String: FormularyRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FormularyRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FormularyRollup) {
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

        func list() -> [FormularyRollup] {
            var out: [FormularyRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFormularyRollupStore() -> any FormularyRollupStore {
        return MemoryFormularyRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFormularyRollupStore: FormularyRollupStore {
        var inner: MemoryFormularyRollupStore
        var cache: TTLCache<FormularyRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryFormularyRollupStore, cache: TTLCache<FormularyRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FormularyRollup? {
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

        func save(_ item: FormularyRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FormularyRollup] {
            return inner.list()
        }
    }

    static func newCachedFormularyRollupStore(_ inner: MemoryFormularyRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FormularyRollupStore {
        return CachedFormularyRollupStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects formulary rollups. Empty fields match all.
    final class FormularyRollupQuery {
        var segment: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FormularyRollup) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [FormularyRollup]) -> [FormularyRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FormularyRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFormularyRollups(_ store: any FormularyRollupStore, query: FormularyRollupQuery) -> [FormularyRollup] {
        return query.apply(store.list())
    }
}
