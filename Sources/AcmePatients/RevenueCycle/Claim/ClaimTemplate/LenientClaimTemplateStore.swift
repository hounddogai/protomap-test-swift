import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps lenient claim templates by code.
    protocol LenientClaimTemplateStore {
        func find(_ code: String) -> LenientClaimTemplate?
        func save(_ item: LenientClaimTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [LenientClaimTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientClaimTemplateStore: LenientClaimTemplateStore {
        var items: [String: LenientClaimTemplate]
        var order: [String]

        init(items: [String: LenientClaimTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientClaimTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientClaimTemplate) {
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

        func list() -> [LenientClaimTemplate] {
            var out: [LenientClaimTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientClaimTemplateStore() -> any LenientClaimTemplateStore {
        return MemoryLenientClaimTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientClaimTemplateStore: LenientClaimTemplateStore {
        var inner: MemoryLenientClaimTemplateStore
        var cache: TTLCache<LenientClaimTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientClaimTemplateStore, cache: TTLCache<LenientClaimTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientClaimTemplate? {
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

        func save(_ item: LenientClaimTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientClaimTemplate] {
            return inner.list()
        }
    }

    static func newCachedLenientClaimTemplateStore(_ inner: MemoryLenientClaimTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientClaimTemplateStore {
        return CachedLenientClaimTemplateStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient claim templates. Empty fields match all.
    final class LenientClaimTemplateQuery {
        var locale: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minAmount: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientClaimTemplate) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientClaimTemplate]) -> [LenientClaimTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientClaimTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientClaimTemplates(_ store: any LenientClaimTemplateStore, query: LenientClaimTemplateQuery) -> [LenientClaimTemplate] {
        return query.apply(store.list())
    }
}
