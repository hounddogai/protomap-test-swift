import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps manual order set templates by code.
    protocol ManualOrderSetTemplateStore {
        func find(_ code: String) -> ManualOrderSetTemplate?
        func save(_ item: ManualOrderSetTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [ManualOrderSetTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualOrderSetTemplateStore: ManualOrderSetTemplateStore {
        var items: [String: ManualOrderSetTemplate]
        var order: [String]

        init(items: [String: ManualOrderSetTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualOrderSetTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualOrderSetTemplate) {
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

        func list() -> [ManualOrderSetTemplate] {
            var out: [ManualOrderSetTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualOrderSetTemplateStore() -> any ManualOrderSetTemplateStore {
        return MemoryManualOrderSetTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualOrderSetTemplateStore: ManualOrderSetTemplateStore {
        var inner: MemoryManualOrderSetTemplateStore
        var cache: TTLCache<ManualOrderSetTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualOrderSetTemplateStore, cache: TTLCache<ManualOrderSetTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualOrderSetTemplate? {
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

        func save(_ item: ManualOrderSetTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualOrderSetTemplate] {
            return inner.list()
        }
    }

    static func newCachedManualOrderSetTemplateStore(_ inner: MemoryManualOrderSetTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualOrderSetTemplateStore {
        return CachedManualOrderSetTemplateStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual order set templates. Empty fields match all.
    final class ManualOrderSetTemplateQuery {
        var unit: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualOrderSetTemplate) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualOrderSetTemplate]) -> [ManualOrderSetTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualOrderSetTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualOrderSetTemplates(_ store: any ManualOrderSetTemplateStore, query: ManualOrderSetTemplateQuery) -> [ManualOrderSetTemplate] {
        return query.apply(store.list())
    }
}
