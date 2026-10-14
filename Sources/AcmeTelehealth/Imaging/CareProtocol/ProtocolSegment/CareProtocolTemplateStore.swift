import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps care protocol templates by code.
    protocol CareProtocolTemplateStore {
        func find(_ code: String) -> CareProtocolTemplate?
        func save(_ item: CareProtocolTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolTemplateStore: CareProtocolTemplateStore {
        var items: [String: CareProtocolTemplate]
        var order: [String]

        init(items: [String: CareProtocolTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolTemplate) {
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

        func list() -> [CareProtocolTemplate] {
            var out: [CareProtocolTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolTemplateStore() -> any CareProtocolTemplateStore {
        return MemoryCareProtocolTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolTemplateStore: CareProtocolTemplateStore {
        var inner: MemoryCareProtocolTemplateStore
        var cache: TTLCache<CareProtocolTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolTemplateStore, cache: TTLCache<CareProtocolTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolTemplate? {
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

        func save(_ item: CareProtocolTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolTemplate] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolTemplateStore(_ inner: MemoryCareProtocolTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolTemplateStore {
        return CachedCareProtocolTemplateStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol templates. Empty fields match all.
    final class CareProtocolTemplateQuery {
        var segment: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolTemplate) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareProtocolTemplate]) -> [CareProtocolTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolTemplates(_ store: any CareProtocolTemplateStore, query: CareProtocolTemplateQuery) -> [CareProtocolTemplate] {
        return query.apply(store.list())
    }
}
