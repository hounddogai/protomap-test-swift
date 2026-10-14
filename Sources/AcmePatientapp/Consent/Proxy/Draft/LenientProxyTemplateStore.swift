import AcmePlatform
import Foundation

extension Consent {
    /// Keeps lenient proxy templates by code.
    protocol LenientProxyTemplateStore {
        func find(_ code: String) -> LenientProxyTemplate?
        func save(_ item: LenientProxyTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [LenientProxyTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientProxyTemplateStore: LenientProxyTemplateStore {
        var items: [String: LenientProxyTemplate]
        var order: [String]

        init(items: [String: LenientProxyTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientProxyTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientProxyTemplate) {
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

        func list() -> [LenientProxyTemplate] {
            var out: [LenientProxyTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientProxyTemplateStore() -> any LenientProxyTemplateStore {
        return MemoryLenientProxyTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientProxyTemplateStore: LenientProxyTemplateStore {
        var inner: MemoryLenientProxyTemplateStore
        var cache: TTLCache<LenientProxyTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientProxyTemplateStore, cache: TTLCache<LenientProxyTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientProxyTemplate? {
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

        func save(_ item: LenientProxyTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientProxyTemplate] {
            return inner.list()
        }
    }

    static func newCachedLenientProxyTemplateStore(_ inner: MemoryLenientProxyTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientProxyTemplateStore {
        return CachedLenientProxyTemplateStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient proxy templates. Empty fields match all.
    final class LenientProxyTemplateQuery {
        var country: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minRefills: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientProxyTemplate) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [LenientProxyTemplate]) -> [LenientProxyTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientProxyTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientProxyTemplates(_ store: any LenientProxyTemplateStore, query: LenientProxyTemplateQuery) -> [LenientProxyTemplate] {
        return query.apply(store.list())
    }
}
