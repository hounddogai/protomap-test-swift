import AcmePlatform
import Foundation

extension Consent {
    /// Keeps legacy language templates by code.
    protocol LegacyLanguageTemplateStore {
        func find(_ code: String) -> LegacyLanguageTemplate?
        func save(_ item: LegacyLanguageTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyLanguageTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyLanguageTemplateStore: LegacyLanguageTemplateStore {
        var items: [String: LegacyLanguageTemplate]
        var order: [String]

        init(items: [String: LegacyLanguageTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyLanguageTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyLanguageTemplate) {
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

        func list() -> [LegacyLanguageTemplate] {
            var out: [LegacyLanguageTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyLanguageTemplateStore() -> any LegacyLanguageTemplateStore {
        return MemoryLegacyLanguageTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyLanguageTemplateStore: LegacyLanguageTemplateStore {
        var inner: MemoryLegacyLanguageTemplateStore
        var cache: TTLCache<LegacyLanguageTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyLanguageTemplateStore, cache: TTLCache<LegacyLanguageTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyLanguageTemplate? {
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

        func save(_ item: LegacyLanguageTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyLanguageTemplate] {
            return inner.list()
        }
    }

    static func newCachedLegacyLanguageTemplateStore(_ inner: MemoryLegacyLanguageTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyLanguageTemplateStore {
        return CachedLegacyLanguageTemplateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy language templates. Empty fields match all.
    final class LegacyLanguageTemplateQuery {
        var locale: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minRefills: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyLanguageTemplate) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyLanguageTemplate]) -> [LegacyLanguageTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyLanguageTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyLanguageTemplates(_ store: any LegacyLanguageTemplateStore, query: LegacyLanguageTemplateQuery) -> [LegacyLanguageTemplate] {
        return query.apply(store.list())
    }
}
