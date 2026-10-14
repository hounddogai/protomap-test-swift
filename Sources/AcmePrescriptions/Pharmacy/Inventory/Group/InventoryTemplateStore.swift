import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps inventory templates by code.
    protocol InventoryTemplateStore {
        func find(_ code: String) -> InventoryTemplate?
        func save(_ item: InventoryTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [InventoryTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInventoryTemplateStore: InventoryTemplateStore {
        var items: [String: InventoryTemplate]
        var order: [String]

        init(items: [String: InventoryTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InventoryTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InventoryTemplate) {
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

        func list() -> [InventoryTemplate] {
            var out: [InventoryTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInventoryTemplateStore() -> any InventoryTemplateStore {
        return MemoryInventoryTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInventoryTemplateStore: InventoryTemplateStore {
        var inner: MemoryInventoryTemplateStore
        var cache: TTLCache<InventoryTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryInventoryTemplateStore, cache: TTLCache<InventoryTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InventoryTemplate? {
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

        func save(_ item: InventoryTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InventoryTemplate] {
            return inner.list()
        }
    }

    static func newCachedInventoryTemplateStore(_ inner: MemoryInventoryTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InventoryTemplateStore {
        return CachedInventoryTemplateStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects inventory templates. Empty fields match all.
    final class InventoryTemplateQuery {
        var category: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minPriority: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InventoryTemplate) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InventoryTemplate]) -> [InventoryTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InventoryTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInventoryTemplates(_ store: any InventoryTemplateStore, query: InventoryTemplateQuery) -> [InventoryTemplate] {
        return query.apply(store.list())
    }
}
