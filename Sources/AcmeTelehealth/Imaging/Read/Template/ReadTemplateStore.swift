import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps read templates by code.
    protocol ReadTemplateStore {
        func find(_ code: String) -> ReadTemplate?
        func save(_ item: ReadTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [ReadTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReadTemplateStore: ReadTemplateStore {
        var items: [String: ReadTemplate]
        var order: [String]

        init(items: [String: ReadTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReadTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReadTemplate) {
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

        func list() -> [ReadTemplate] {
            var out: [ReadTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReadTemplateStore() -> any ReadTemplateStore {
        return MemoryReadTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReadTemplateStore: ReadTemplateStore {
        var inner: MemoryReadTemplateStore
        var cache: TTLCache<ReadTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryReadTemplateStore, cache: TTLCache<ReadTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReadTemplate? {
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

        func save(_ item: ReadTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReadTemplate] {
            return inner.list()
        }
    }

    static func newCachedReadTemplateStore(_ inner: MemoryReadTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReadTemplateStore {
        return CachedReadTemplateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects read templates. Empty fields match all.
    final class ReadTemplateQuery {
        var locale: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReadTemplate) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReadTemplate]) -> [ReadTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReadTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReadTemplates(_ store: any ReadTemplateStore, query: ReadTemplateQuery) -> [ReadTemplate] {
        return query.apply(store.list())
    }
}
