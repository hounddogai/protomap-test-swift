import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps rounding templates by code.
    protocol RoundingTemplateStore {
        func find(_ code: String) -> RoundingTemplate?
        func save(_ item: RoundingTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [RoundingTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRoundingTemplateStore: RoundingTemplateStore {
        var items: [String: RoundingTemplate]
        var order: [String]

        init(items: [String: RoundingTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RoundingTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RoundingTemplate) {
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

        func list() -> [RoundingTemplate] {
            var out: [RoundingTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRoundingTemplateStore() -> any RoundingTemplateStore {
        return MemoryRoundingTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRoundingTemplateStore: RoundingTemplateStore {
        var inner: MemoryRoundingTemplateStore
        var cache: TTLCache<RoundingTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryRoundingTemplateStore, cache: TTLCache<RoundingTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RoundingTemplate? {
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

        func save(_ item: RoundingTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RoundingTemplate] {
            return inner.list()
        }
    }

    static func newCachedRoundingTemplateStore(_ inner: MemoryRoundingTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RoundingTemplateStore {
        return CachedRoundingTemplateStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rounding templates. Empty fields match all.
    final class RoundingTemplateQuery {
        var locale: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minMargin: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RoundingTemplate) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RoundingTemplate]) -> [RoundingTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RoundingTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRoundingTemplates(_ store: any RoundingTemplateStore, query: RoundingTemplateQuery) -> [RoundingTemplate] {
        return query.apply(store.list())
    }
}
