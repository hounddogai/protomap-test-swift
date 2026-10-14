import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps formulary windows by code.
    protocol FormularyWindowStore {
        func find(_ code: String) -> FormularyWindow?
        func save(_ item: FormularyWindow)
        func remove(_ code: String) -> Bool
        func list() -> [FormularyWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFormularyWindowStore: FormularyWindowStore {
        var items: [String: FormularyWindow]
        var order: [String]

        init(items: [String: FormularyWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FormularyWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FormularyWindow) {
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

        func list() -> [FormularyWindow] {
            var out: [FormularyWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFormularyWindowStore() -> any FormularyWindowStore {
        return MemoryFormularyWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFormularyWindowStore: FormularyWindowStore {
        var inner: MemoryFormularyWindowStore
        var cache: TTLCache<FormularyWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryFormularyWindowStore, cache: TTLCache<FormularyWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FormularyWindow? {
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

        func save(_ item: FormularyWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FormularyWindow] {
            return inner.list()
        }
    }

    static func newCachedFormularyWindowStore(_ inner: MemoryFormularyWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FormularyWindowStore {
        return CachedFormularyWindowStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects formulary windows. Empty fields match all.
    final class FormularyWindowQuery {
        var channel: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FormularyWindow) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FormularyWindow]) -> [FormularyWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FormularyWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFormularyWindows(_ store: any FormularyWindowStore, query: FormularyWindowQuery) -> [FormularyWindow] {
        return query.apply(store.list())
    }
}
