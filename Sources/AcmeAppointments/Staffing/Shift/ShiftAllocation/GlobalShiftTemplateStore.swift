import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps global shift templates by code.
    protocol GlobalShiftTemplateStore {
        func find(_ code: String) -> GlobalShiftTemplate?
        func save(_ item: GlobalShiftTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalShiftTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalShiftTemplateStore: GlobalShiftTemplateStore {
        var items: [String: GlobalShiftTemplate]
        var order: [String]

        init(items: [String: GlobalShiftTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalShiftTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalShiftTemplate) {
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

        func list() -> [GlobalShiftTemplate] {
            var out: [GlobalShiftTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalShiftTemplateStore() -> any GlobalShiftTemplateStore {
        return MemoryGlobalShiftTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalShiftTemplateStore: GlobalShiftTemplateStore {
        var inner: MemoryGlobalShiftTemplateStore
        var cache: TTLCache<GlobalShiftTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalShiftTemplateStore, cache: TTLCache<GlobalShiftTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalShiftTemplate? {
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

        func save(_ item: GlobalShiftTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalShiftTemplate] {
            return inner.list()
        }
    }

    static func newCachedGlobalShiftTemplateStore(_ inner: MemoryGlobalShiftTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalShiftTemplateStore {
        return CachedGlobalShiftTemplateStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global shift templates. Empty fields match all.
    final class GlobalShiftTemplateQuery {
        var label: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalShiftTemplate) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalShiftTemplate]) -> [GlobalShiftTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalShiftTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalShiftTemplates(_ store: any GlobalShiftTemplateStore, query: GlobalShiftTemplateQuery) -> [GlobalShiftTemplate] {
        return query.apply(store.list())
    }
}
