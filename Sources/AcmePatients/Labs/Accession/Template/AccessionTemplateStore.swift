import AcmePlatform
import Foundation

extension Labs {
    /// Keeps accession templates by code.
    protocol AccessionTemplateStore {
        func find(_ code: String) -> AccessionTemplate?
        func save(_ item: AccessionTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [AccessionTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAccessionTemplateStore: AccessionTemplateStore {
        var items: [String: AccessionTemplate]
        var order: [String]

        init(items: [String: AccessionTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AccessionTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AccessionTemplate) {
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

        func list() -> [AccessionTemplate] {
            var out: [AccessionTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAccessionTemplateStore() -> any AccessionTemplateStore {
        return MemoryAccessionTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAccessionTemplateStore: AccessionTemplateStore {
        var inner: MemoryAccessionTemplateStore
        var cache: TTLCache<AccessionTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryAccessionTemplateStore, cache: TTLCache<AccessionTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AccessionTemplate? {
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

        func save(_ item: AccessionTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AccessionTemplate] {
            return inner.list()
        }
    }

    static func newCachedAccessionTemplateStore(_ inner: MemoryAccessionTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AccessionTemplateStore {
        return CachedAccessionTemplateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects accession templates. Empty fields match all.
    final class AccessionTemplateQuery {
        var title: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minLimit: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AccessionTemplate) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AccessionTemplate]) -> [AccessionTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AccessionTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAccessionTemplates(_ store: any AccessionTemplateStore, query: AccessionTemplateQuery) -> [AccessionTemplate] {
        return query.apply(store.list())
    }
}
