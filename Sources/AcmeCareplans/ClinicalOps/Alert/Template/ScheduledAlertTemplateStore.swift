import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps scheduled alert templates by code.
    protocol ScheduledAlertTemplateStore {
        func find(_ code: String) -> ScheduledAlertTemplate?
        func save(_ item: ScheduledAlertTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledAlertTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledAlertTemplateStore: ScheduledAlertTemplateStore {
        var items: [String: ScheduledAlertTemplate]
        var order: [String]

        init(items: [String: ScheduledAlertTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledAlertTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledAlertTemplate) {
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

        func list() -> [ScheduledAlertTemplate] {
            var out: [ScheduledAlertTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledAlertTemplateStore() -> any ScheduledAlertTemplateStore {
        return MemoryScheduledAlertTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledAlertTemplateStore: ScheduledAlertTemplateStore {
        var inner: MemoryScheduledAlertTemplateStore
        var cache: TTLCache<ScheduledAlertTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledAlertTemplateStore, cache: TTLCache<ScheduledAlertTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledAlertTemplate? {
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

        func save(_ item: ScheduledAlertTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledAlertTemplate] {
            return inner.list()
        }
    }

    static func newCachedScheduledAlertTemplateStore(_ inner: MemoryScheduledAlertTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledAlertTemplateStore {
        return CachedScheduledAlertTemplateStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled alert templates. Empty fields match all.
    final class ScheduledAlertTemplateQuery {
        var facility: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minRefills: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledAlertTemplate) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledAlertTemplate]) -> [ScheduledAlertTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledAlertTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledAlertTemplates(_ store: any ScheduledAlertTemplateStore, query: ScheduledAlertTemplateQuery) -> [ScheduledAlertTemplate] {
        return query.apply(store.list())
    }
}
