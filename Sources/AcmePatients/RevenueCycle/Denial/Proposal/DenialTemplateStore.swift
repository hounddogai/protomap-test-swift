import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps denial templates by code.
    protocol DenialTemplateStore {
        func find(_ code: String) -> DenialTemplate?
        func save(_ item: DenialTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [DenialTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDenialTemplateStore: DenialTemplateStore {
        var items: [String: DenialTemplate]
        var order: [String]

        init(items: [String: DenialTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DenialTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DenialTemplate) {
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

        func list() -> [DenialTemplate] {
            var out: [DenialTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDenialTemplateStore() -> any DenialTemplateStore {
        return MemoryDenialTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDenialTemplateStore: DenialTemplateStore {
        var inner: MemoryDenialTemplateStore
        var cache: TTLCache<DenialTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryDenialTemplateStore, cache: TTLCache<DenialTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DenialTemplate? {
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

        func save(_ item: DenialTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DenialTemplate] {
            return inner.list()
        }
    }

    static func newCachedDenialTemplateStore(_ inner: MemoryDenialTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DenialTemplateStore {
        return CachedDenialTemplateStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects denial templates. Empty fields match all.
    final class DenialTemplateQuery {
        var channel: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DenialTemplate) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [DenialTemplate]) -> [DenialTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DenialTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDenialTemplates(_ store: any DenialTemplateStore, query: DenialTemplateQuery) -> [DenialTemplate] {
        return query.apply(store.list())
    }
}
