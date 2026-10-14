import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps capped order set templates by code.
    protocol CappedOrderSetTemplateStore {
        func find(_ code: String) -> CappedOrderSetTemplate?
        func save(_ item: CappedOrderSetTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [CappedOrderSetTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedOrderSetTemplateStore: CappedOrderSetTemplateStore {
        var items: [String: CappedOrderSetTemplate]
        var order: [String]

        init(items: [String: CappedOrderSetTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedOrderSetTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedOrderSetTemplate) {
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

        func list() -> [CappedOrderSetTemplate] {
            var out: [CappedOrderSetTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedOrderSetTemplateStore() -> any CappedOrderSetTemplateStore {
        return MemoryCappedOrderSetTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedOrderSetTemplateStore: CappedOrderSetTemplateStore {
        var inner: MemoryCappedOrderSetTemplateStore
        var cache: TTLCache<CappedOrderSetTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedOrderSetTemplateStore, cache: TTLCache<CappedOrderSetTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedOrderSetTemplate? {
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

        func save(_ item: CappedOrderSetTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedOrderSetTemplate] {
            return inner.list()
        }
    }

    static func newCachedCappedOrderSetTemplateStore(_ inner: MemoryCappedOrderSetTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedOrderSetTemplateStore {
        return CachedCappedOrderSetTemplateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped order set templates. Empty fields match all.
    final class CappedOrderSetTemplateQuery {
        var ward: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minCopay: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedOrderSetTemplate) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedOrderSetTemplate]) -> [CappedOrderSetTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedOrderSetTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedOrderSetTemplates(_ store: any CappedOrderSetTemplateStore, query: CappedOrderSetTemplateQuery) -> [CappedOrderSetTemplate] {
        return query.apply(store.list())
    }
}
