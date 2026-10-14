import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps seasonal order set templates by code.
    protocol SeasonalOrderSetTemplateStore {
        func find(_ code: String) -> SeasonalOrderSetTemplate?
        func save(_ item: SeasonalOrderSetTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalOrderSetTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalOrderSetTemplateStore: SeasonalOrderSetTemplateStore {
        var items: [String: SeasonalOrderSetTemplate]
        var order: [String]

        init(items: [String: SeasonalOrderSetTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalOrderSetTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalOrderSetTemplate) {
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

        func list() -> [SeasonalOrderSetTemplate] {
            var out: [SeasonalOrderSetTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalOrderSetTemplateStore() -> any SeasonalOrderSetTemplateStore {
        return MemorySeasonalOrderSetTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalOrderSetTemplateStore: SeasonalOrderSetTemplateStore {
        var inner: MemorySeasonalOrderSetTemplateStore
        var cache: TTLCache<SeasonalOrderSetTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalOrderSetTemplateStore, cache: TTLCache<SeasonalOrderSetTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalOrderSetTemplate? {
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

        func save(_ item: SeasonalOrderSetTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalOrderSetTemplate] {
            return inner.list()
        }
    }

    static func newCachedSeasonalOrderSetTemplateStore(_ inner: MemorySeasonalOrderSetTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalOrderSetTemplateStore {
        return CachedSeasonalOrderSetTemplateStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal order set templates. Empty fields match all.
    final class SeasonalOrderSetTemplateQuery {
        var label: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minRate: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalOrderSetTemplate) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalOrderSetTemplate]) -> [SeasonalOrderSetTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalOrderSetTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalOrderSetTemplates(_ store: any SeasonalOrderSetTemplateStore, query: SeasonalOrderSetTemplateQuery) -> [SeasonalOrderSetTemplate] {
        return query.apply(store.list())
    }
}
