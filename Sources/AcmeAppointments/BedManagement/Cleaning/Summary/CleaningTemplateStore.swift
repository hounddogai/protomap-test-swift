import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps cleaning templates by code.
    protocol CleaningTemplateStore {
        func find(_ code: String) -> CleaningTemplate?
        func save(_ item: CleaningTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [CleaningTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCleaningTemplateStore: CleaningTemplateStore {
        var items: [String: CleaningTemplate]
        var order: [String]

        init(items: [String: CleaningTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CleaningTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CleaningTemplate) {
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

        func list() -> [CleaningTemplate] {
            var out: [CleaningTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCleaningTemplateStore() -> any CleaningTemplateStore {
        return MemoryCleaningTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCleaningTemplateStore: CleaningTemplateStore {
        var inner: MemoryCleaningTemplateStore
        var cache: TTLCache<CleaningTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryCleaningTemplateStore, cache: TTLCache<CleaningTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CleaningTemplate? {
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

        func save(_ item: CleaningTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CleaningTemplate] {
            return inner.list()
        }
    }

    static func newCachedCleaningTemplateStore(_ inner: MemoryCleaningTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CleaningTemplateStore {
        return CachedCleaningTemplateStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects cleaning templates. Empty fields match all.
    final class CleaningTemplateQuery {
        var region: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CleaningTemplate) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [CleaningTemplate]) -> [CleaningTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CleaningTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCleaningTemplates(_ store: any CleaningTemplateStore, query: CleaningTemplateQuery) -> [CleaningTemplate] {
        return query.apply(store.list())
    }
}
