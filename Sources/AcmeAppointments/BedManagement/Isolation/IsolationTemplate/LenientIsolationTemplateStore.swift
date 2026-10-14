import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps lenient isolation templates by code.
    protocol LenientIsolationTemplateStore {
        func find(_ code: String) -> LenientIsolationTemplate?
        func save(_ item: LenientIsolationTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [LenientIsolationTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientIsolationTemplateStore: LenientIsolationTemplateStore {
        var items: [String: LenientIsolationTemplate]
        var order: [String]

        init(items: [String: LenientIsolationTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientIsolationTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientIsolationTemplate) {
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

        func list() -> [LenientIsolationTemplate] {
            var out: [LenientIsolationTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientIsolationTemplateStore() -> any LenientIsolationTemplateStore {
        return MemoryLenientIsolationTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientIsolationTemplateStore: LenientIsolationTemplateStore {
        var inner: MemoryLenientIsolationTemplateStore
        var cache: TTLCache<LenientIsolationTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientIsolationTemplateStore, cache: TTLCache<LenientIsolationTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientIsolationTemplate? {
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

        func save(_ item: LenientIsolationTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientIsolationTemplate] {
            return inner.list()
        }
    }

    static func newCachedLenientIsolationTemplateStore(_ inner: MemoryLenientIsolationTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientIsolationTemplateStore {
        return CachedLenientIsolationTemplateStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient isolation templates. Empty fields match all.
    final class LenientIsolationTemplateQuery {
        var locale: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientIsolationTemplate) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [LenientIsolationTemplate]) -> [LenientIsolationTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientIsolationTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientIsolationTemplates(_ store: any LenientIsolationTemplateStore, query: LenientIsolationTemplateQuery) -> [LenientIsolationTemplate] {
        return query.apply(store.list())
    }
}
