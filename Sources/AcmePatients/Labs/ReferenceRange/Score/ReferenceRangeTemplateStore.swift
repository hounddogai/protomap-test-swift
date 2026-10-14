import AcmePlatform
import Foundation

extension Labs {
    /// Keeps reference range templates by code.
    protocol ReferenceRangeTemplateStore {
        func find(_ code: String) -> ReferenceRangeTemplate?
        func save(_ item: ReferenceRangeTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [ReferenceRangeTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferenceRangeTemplateStore: ReferenceRangeTemplateStore {
        var items: [String: ReferenceRangeTemplate]
        var order: [String]

        init(items: [String: ReferenceRangeTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferenceRangeTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferenceRangeTemplate) {
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

        func list() -> [ReferenceRangeTemplate] {
            var out: [ReferenceRangeTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferenceRangeTemplateStore() -> any ReferenceRangeTemplateStore {
        return MemoryReferenceRangeTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferenceRangeTemplateStore: ReferenceRangeTemplateStore {
        var inner: MemoryReferenceRangeTemplateStore
        var cache: TTLCache<ReferenceRangeTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferenceRangeTemplateStore, cache: TTLCache<ReferenceRangeTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferenceRangeTemplate? {
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

        func save(_ item: ReferenceRangeTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferenceRangeTemplate] {
            return inner.list()
        }
    }

    static func newCachedReferenceRangeTemplateStore(_ inner: MemoryReferenceRangeTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferenceRangeTemplateStore {
        return CachedReferenceRangeTemplateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects reference range templates. Empty fields match all.
    final class ReferenceRangeTemplateQuery {
        var title: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferenceRangeTemplate) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [ReferenceRangeTemplate]) -> [ReferenceRangeTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferenceRangeTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferenceRangeTemplates(_ store: any ReferenceRangeTemplateStore, query: ReferenceRangeTemplateQuery) -> [ReferenceRangeTemplate] {
        return query.apply(store.list())
    }
}
