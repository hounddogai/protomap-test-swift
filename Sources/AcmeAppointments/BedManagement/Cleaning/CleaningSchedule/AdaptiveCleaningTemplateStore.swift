import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps adaptive cleaning templates by code.
    protocol AdaptiveCleaningTemplateStore {
        func find(_ code: String) -> AdaptiveCleaningTemplate?
        func save(_ item: AdaptiveCleaningTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveCleaningTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveCleaningTemplateStore: AdaptiveCleaningTemplateStore {
        var items: [String: AdaptiveCleaningTemplate]
        var order: [String]

        init(items: [String: AdaptiveCleaningTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveCleaningTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveCleaningTemplate) {
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

        func list() -> [AdaptiveCleaningTemplate] {
            var out: [AdaptiveCleaningTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveCleaningTemplateStore() -> any AdaptiveCleaningTemplateStore {
        return MemoryAdaptiveCleaningTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveCleaningTemplateStore: AdaptiveCleaningTemplateStore {
        var inner: MemoryAdaptiveCleaningTemplateStore
        var cache: TTLCache<AdaptiveCleaningTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveCleaningTemplateStore, cache: TTLCache<AdaptiveCleaningTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveCleaningTemplate? {
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

        func save(_ item: AdaptiveCleaningTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveCleaningTemplate] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveCleaningTemplateStore(_ inner: MemoryAdaptiveCleaningTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveCleaningTemplateStore {
        return CachedAdaptiveCleaningTemplateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive cleaning templates. Empty fields match all.
    final class AdaptiveCleaningTemplateQuery {
        var region: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveCleaningTemplate) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveCleaningTemplate]) -> [AdaptiveCleaningTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveCleaningTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveCleaningTemplates(_ store: any AdaptiveCleaningTemplateStore, query: AdaptiveCleaningTemplateQuery) -> [AdaptiveCleaningTemplate] {
        return query.apply(store.list())
    }
}
