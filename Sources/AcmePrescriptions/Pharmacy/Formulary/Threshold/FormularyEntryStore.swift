import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps formulary entries by code.
    protocol FormularyEntryStore {
        func find(_ code: String) -> FormularyEntry?
        func save(_ item: FormularyEntry)
        func remove(_ code: String) -> Bool
        func list() -> [FormularyEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFormularyEntryStore: FormularyEntryStore {
        var items: [String: FormularyEntry]
        var order: [String]

        init(items: [String: FormularyEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FormularyEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FormularyEntry) {
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

        func list() -> [FormularyEntry] {
            var out: [FormularyEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFormularyEntryStore() -> any FormularyEntryStore {
        return MemoryFormularyEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFormularyEntryStore: FormularyEntryStore {
        var inner: MemoryFormularyEntryStore
        var cache: TTLCache<FormularyEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryFormularyEntryStore, cache: TTLCache<FormularyEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FormularyEntry? {
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

        func save(_ item: FormularyEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FormularyEntry] {
            return inner.list()
        }
    }

    static func newCachedFormularyEntryStore(_ inner: MemoryFormularyEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FormularyEntryStore {
        return CachedFormularyEntryStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects formulary entries. Empty fields match all.
    final class FormularyEntryQuery {
        var label: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FormularyEntry) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FormularyEntry]) -> [FormularyEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FormularyEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFormularyEntries(_ store: any FormularyEntryStore, query: FormularyEntryQuery) -> [FormularyEntry] {
        return query.apply(store.list())
    }
}
