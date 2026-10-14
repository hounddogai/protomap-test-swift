import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps capped outreach templates by code.
    protocol CappedOutreachTemplateStore {
        func find(_ code: String) -> CappedOutreachTemplate?
        func save(_ item: CappedOutreachTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [CappedOutreachTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedOutreachTemplateStore: CappedOutreachTemplateStore {
        var items: [String: CappedOutreachTemplate]
        var order: [String]

        init(items: [String: CappedOutreachTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedOutreachTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedOutreachTemplate) {
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

        func list() -> [CappedOutreachTemplate] {
            var out: [CappedOutreachTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedOutreachTemplateStore() -> any CappedOutreachTemplateStore {
        return MemoryCappedOutreachTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedOutreachTemplateStore: CappedOutreachTemplateStore {
        var inner: MemoryCappedOutreachTemplateStore
        var cache: TTLCache<CappedOutreachTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedOutreachTemplateStore, cache: TTLCache<CappedOutreachTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedOutreachTemplate? {
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

        func save(_ item: CappedOutreachTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedOutreachTemplate] {
            return inner.list()
        }
    }

    static func newCachedCappedOutreachTemplateStore(_ inner: MemoryCappedOutreachTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedOutreachTemplateStore {
        return CachedCappedOutreachTemplateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped outreach templates. Empty fields match all.
    final class CappedOutreachTemplateQuery {
        var source: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minPriority: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedOutreachTemplate) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedOutreachTemplate]) -> [CappedOutreachTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedOutreachTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedOutreachTemplates(_ store: any CappedOutreachTemplateStore, query: CappedOutreachTemplateQuery) -> [CappedOutreachTemplate] {
        return query.apply(store.list())
    }
}
