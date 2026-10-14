import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps fallback cleaning templates by code.
    protocol FallbackCleaningTemplateStore {
        func find(_ code: String) -> FallbackCleaningTemplate?
        func save(_ item: FallbackCleaningTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackCleaningTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackCleaningTemplateStore: FallbackCleaningTemplateStore {
        var items: [String: FallbackCleaningTemplate]
        var order: [String]

        init(items: [String: FallbackCleaningTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackCleaningTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackCleaningTemplate) {
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

        func list() -> [FallbackCleaningTemplate] {
            var out: [FallbackCleaningTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackCleaningTemplateStore() -> any FallbackCleaningTemplateStore {
        return MemoryFallbackCleaningTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackCleaningTemplateStore: FallbackCleaningTemplateStore {
        var inner: MemoryFallbackCleaningTemplateStore
        var cache: TTLCache<FallbackCleaningTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackCleaningTemplateStore, cache: TTLCache<FallbackCleaningTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackCleaningTemplate? {
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

        func save(_ item: FallbackCleaningTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackCleaningTemplate] {
            return inner.list()
        }
    }

    static func newCachedFallbackCleaningTemplateStore(_ inner: MemoryFallbackCleaningTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackCleaningTemplateStore {
        return CachedFallbackCleaningTemplateStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback cleaning templates. Empty fields match all.
    final class FallbackCleaningTemplateQuery {
        var unit: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackCleaningTemplate) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackCleaningTemplate]) -> [FallbackCleaningTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackCleaningTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackCleaningTemplates(_ store: any FallbackCleaningTemplateStore, query: FallbackCleaningTemplateQuery) -> [FallbackCleaningTemplate] {
        return query.apply(store.list())
    }
}
