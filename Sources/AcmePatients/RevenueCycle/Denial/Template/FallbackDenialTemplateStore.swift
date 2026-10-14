import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps fallback denial templates by code.
    protocol FallbackDenialTemplateStore {
        func find(_ code: String) -> FallbackDenialTemplate?
        func save(_ item: FallbackDenialTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackDenialTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackDenialTemplateStore: FallbackDenialTemplateStore {
        var items: [String: FallbackDenialTemplate]
        var order: [String]

        init(items: [String: FallbackDenialTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackDenialTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackDenialTemplate) {
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

        func list() -> [FallbackDenialTemplate] {
            var out: [FallbackDenialTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackDenialTemplateStore() -> any FallbackDenialTemplateStore {
        return MemoryFallbackDenialTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackDenialTemplateStore: FallbackDenialTemplateStore {
        var inner: MemoryFallbackDenialTemplateStore
        var cache: TTLCache<FallbackDenialTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackDenialTemplateStore, cache: TTLCache<FallbackDenialTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackDenialTemplate? {
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

        func save(_ item: FallbackDenialTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackDenialTemplate] {
            return inner.list()
        }
    }

    static func newCachedFallbackDenialTemplateStore(_ inner: MemoryFallbackDenialTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackDenialTemplateStore {
        return CachedFallbackDenialTemplateStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback denial templates. Empty fields match all.
    final class FallbackDenialTemplateQuery {
        var channel: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackDenialTemplate) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [FallbackDenialTemplate]) -> [FallbackDenialTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackDenialTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackDenialTemplates(_ store: any FallbackDenialTemplateStore, query: FallbackDenialTemplateQuery) -> [FallbackDenialTemplate] {
        return query.apply(store.list())
    }
}
