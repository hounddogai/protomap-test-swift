import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps manual denial templates by code.
    protocol ManualDenialTemplateStore {
        func find(_ code: String) -> ManualDenialTemplate?
        func save(_ item: ManualDenialTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [ManualDenialTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualDenialTemplateStore: ManualDenialTemplateStore {
        var items: [String: ManualDenialTemplate]
        var order: [String]

        init(items: [String: ManualDenialTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualDenialTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualDenialTemplate) {
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

        func list() -> [ManualDenialTemplate] {
            var out: [ManualDenialTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualDenialTemplateStore() -> any ManualDenialTemplateStore {
        return MemoryManualDenialTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualDenialTemplateStore: ManualDenialTemplateStore {
        var inner: MemoryManualDenialTemplateStore
        var cache: TTLCache<ManualDenialTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualDenialTemplateStore, cache: TTLCache<ManualDenialTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualDenialTemplate? {
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

        func save(_ item: ManualDenialTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualDenialTemplate] {
            return inner.list()
        }
    }

    static func newCachedManualDenialTemplateStore(_ inner: MemoryManualDenialTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualDenialTemplateStore {
        return CachedManualDenialTemplateStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual denial templates. Empty fields match all.
    final class ManualDenialTemplateQuery {
        var title: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualDenialTemplate) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualDenialTemplate]) -> [ManualDenialTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualDenialTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualDenialTemplates(_ store: any ManualDenialTemplateStore, query: ManualDenialTemplateQuery) -> [ManualDenialTemplate] {
        return query.apply(store.list())
    }
}
