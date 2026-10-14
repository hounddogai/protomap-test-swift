import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps fallback transfer templates by code.
    protocol FallbackTransferTemplateStore {
        func find(_ code: String) -> FallbackTransferTemplate?
        func save(_ item: FallbackTransferTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackTransferTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackTransferTemplateStore: FallbackTransferTemplateStore {
        var items: [String: FallbackTransferTemplate]
        var order: [String]

        init(items: [String: FallbackTransferTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackTransferTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackTransferTemplate) {
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

        func list() -> [FallbackTransferTemplate] {
            var out: [FallbackTransferTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackTransferTemplateStore() -> any FallbackTransferTemplateStore {
        return MemoryFallbackTransferTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackTransferTemplateStore: FallbackTransferTemplateStore {
        var inner: MemoryFallbackTransferTemplateStore
        var cache: TTLCache<FallbackTransferTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackTransferTemplateStore, cache: TTLCache<FallbackTransferTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackTransferTemplate? {
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

        func save(_ item: FallbackTransferTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackTransferTemplate] {
            return inner.list()
        }
    }

    static func newCachedFallbackTransferTemplateStore(_ inner: MemoryFallbackTransferTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackTransferTemplateStore {
        return CachedFallbackTransferTemplateStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback transfer templates. Empty fields match all.
    final class FallbackTransferTemplateQuery {
        var country: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackTransferTemplate) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackTransferTemplate]) -> [FallbackTransferTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackTransferTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackTransferTemplates(_ store: any FallbackTransferTemplateStore, query: FallbackTransferTemplateQuery) -> [FallbackTransferTemplate] {
        return query.apply(store.list())
    }
}
