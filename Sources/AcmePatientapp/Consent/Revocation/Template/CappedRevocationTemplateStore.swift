import AcmePlatform
import Foundation

extension Consent {
    /// Keeps capped revocation templates by code.
    protocol CappedRevocationTemplateStore {
        func find(_ code: String) -> CappedRevocationTemplate?
        func save(_ item: CappedRevocationTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [CappedRevocationTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedRevocationTemplateStore: CappedRevocationTemplateStore {
        var items: [String: CappedRevocationTemplate]
        var order: [String]

        init(items: [String: CappedRevocationTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedRevocationTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedRevocationTemplate) {
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

        func list() -> [CappedRevocationTemplate] {
            var out: [CappedRevocationTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedRevocationTemplateStore() -> any CappedRevocationTemplateStore {
        return MemoryCappedRevocationTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedRevocationTemplateStore: CappedRevocationTemplateStore {
        var inner: MemoryCappedRevocationTemplateStore
        var cache: TTLCache<CappedRevocationTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedRevocationTemplateStore, cache: TTLCache<CappedRevocationTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedRevocationTemplate? {
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

        func save(_ item: CappedRevocationTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedRevocationTemplate] {
            return inner.list()
        }
    }

    static func newCachedCappedRevocationTemplateStore(_ inner: MemoryCappedRevocationTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedRevocationTemplateStore {
        return CachedCappedRevocationTemplateStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped revocation templates. Empty fields match all.
    final class CappedRevocationTemplateQuery {
        var title: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedRevocationTemplate) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedRevocationTemplate]) -> [CappedRevocationTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedRevocationTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedRevocationTemplates(_ store: any CappedRevocationTemplateStore, query: CappedRevocationTemplateQuery) -> [CappedRevocationTemplate] {
        return query.apply(store.list())
    }
}
