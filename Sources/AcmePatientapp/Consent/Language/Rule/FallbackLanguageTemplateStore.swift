import AcmePlatform
import Foundation

extension Consent {
    /// Keeps fallback language templates by code.
    protocol FallbackLanguageTemplateStore {
        func find(_ code: String) -> FallbackLanguageTemplate?
        func save(_ item: FallbackLanguageTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackLanguageTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackLanguageTemplateStore: FallbackLanguageTemplateStore {
        var items: [String: FallbackLanguageTemplate]
        var order: [String]

        init(items: [String: FallbackLanguageTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackLanguageTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackLanguageTemplate) {
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

        func list() -> [FallbackLanguageTemplate] {
            var out: [FallbackLanguageTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackLanguageTemplateStore() -> any FallbackLanguageTemplateStore {
        return MemoryFallbackLanguageTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackLanguageTemplateStore: FallbackLanguageTemplateStore {
        var inner: MemoryFallbackLanguageTemplateStore
        var cache: TTLCache<FallbackLanguageTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackLanguageTemplateStore, cache: TTLCache<FallbackLanguageTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackLanguageTemplate? {
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

        func save(_ item: FallbackLanguageTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackLanguageTemplate] {
            return inner.list()
        }
    }

    static func newCachedFallbackLanguageTemplateStore(_ inner: MemoryFallbackLanguageTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackLanguageTemplateStore {
        return CachedFallbackLanguageTemplateStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback language templates. Empty fields match all.
    final class FallbackLanguageTemplateQuery {
        var title: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackLanguageTemplate) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [FallbackLanguageTemplate]) -> [FallbackLanguageTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackLanguageTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackLanguageTemplates(_ store: any FallbackLanguageTemplateStore, query: FallbackLanguageTemplateQuery) -> [FallbackLanguageTemplate] {
        return query.apply(store.list())
    }
}
