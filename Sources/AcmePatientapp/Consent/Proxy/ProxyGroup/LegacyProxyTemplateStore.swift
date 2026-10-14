import AcmePlatform
import Foundation

extension Consent {
    /// Keeps legacy proxy templates by code.
    protocol LegacyProxyTemplateStore {
        func find(_ code: String) -> LegacyProxyTemplate?
        func save(_ item: LegacyProxyTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyProxyTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyProxyTemplateStore: LegacyProxyTemplateStore {
        var items: [String: LegacyProxyTemplate]
        var order: [String]

        init(items: [String: LegacyProxyTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyProxyTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyProxyTemplate) {
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

        func list() -> [LegacyProxyTemplate] {
            var out: [LegacyProxyTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyProxyTemplateStore() -> any LegacyProxyTemplateStore {
        return MemoryLegacyProxyTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyProxyTemplateStore: LegacyProxyTemplateStore {
        var inner: MemoryLegacyProxyTemplateStore
        var cache: TTLCache<LegacyProxyTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyProxyTemplateStore, cache: TTLCache<LegacyProxyTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyProxyTemplate? {
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

        func save(_ item: LegacyProxyTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyProxyTemplate] {
            return inner.list()
        }
    }

    static func newCachedLegacyProxyTemplateStore(_ inner: MemoryLegacyProxyTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyProxyTemplateStore {
        return CachedLegacyProxyTemplateStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy proxy templates. Empty fields match all.
    final class LegacyProxyTemplateQuery {
        var ward: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyProxyTemplate) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyProxyTemplate]) -> [LegacyProxyTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyProxyTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyProxyTemplates(_ store: any LegacyProxyTemplateStore, query: LegacyProxyTemplateQuery) -> [LegacyProxyTemplate] {
        return query.apply(store.list())
    }
}
