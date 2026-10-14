import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps global rounding templates by code.
    protocol GlobalRoundingTemplateStore {
        func find(_ code: String) -> GlobalRoundingTemplate?
        func save(_ item: GlobalRoundingTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalRoundingTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalRoundingTemplateStore: GlobalRoundingTemplateStore {
        var items: [String: GlobalRoundingTemplate]
        var order: [String]

        init(items: [String: GlobalRoundingTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalRoundingTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalRoundingTemplate) {
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

        func list() -> [GlobalRoundingTemplate] {
            var out: [GlobalRoundingTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalRoundingTemplateStore() -> any GlobalRoundingTemplateStore {
        return MemoryGlobalRoundingTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalRoundingTemplateStore: GlobalRoundingTemplateStore {
        var inner: MemoryGlobalRoundingTemplateStore
        var cache: TTLCache<GlobalRoundingTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalRoundingTemplateStore, cache: TTLCache<GlobalRoundingTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalRoundingTemplate? {
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

        func save(_ item: GlobalRoundingTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalRoundingTemplate] {
            return inner.list()
        }
    }

    static func newCachedGlobalRoundingTemplateStore(_ inner: MemoryGlobalRoundingTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalRoundingTemplateStore {
        return CachedGlobalRoundingTemplateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global rounding templates. Empty fields match all.
    final class GlobalRoundingTemplateQuery {
        var name: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalRoundingTemplate) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalRoundingTemplate]) -> [GlobalRoundingTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalRoundingTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalRoundingTemplates(_ store: any GlobalRoundingTemplateStore, query: GlobalRoundingTemplateQuery) -> [GlobalRoundingTemplate] {
        return query.apply(store.list())
    }
}
