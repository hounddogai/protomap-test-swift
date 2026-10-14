import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps scheduled shift templates by code.
    protocol ScheduledShiftTemplateStore {
        func find(_ code: String) -> ScheduledShiftTemplate?
        func save(_ item: ScheduledShiftTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledShiftTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledShiftTemplateStore: ScheduledShiftTemplateStore {
        var items: [String: ScheduledShiftTemplate]
        var order: [String]

        init(items: [String: ScheduledShiftTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledShiftTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledShiftTemplate) {
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

        func list() -> [ScheduledShiftTemplate] {
            var out: [ScheduledShiftTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledShiftTemplateStore() -> any ScheduledShiftTemplateStore {
        return MemoryScheduledShiftTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledShiftTemplateStore: ScheduledShiftTemplateStore {
        var inner: MemoryScheduledShiftTemplateStore
        var cache: TTLCache<ScheduledShiftTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledShiftTemplateStore, cache: TTLCache<ScheduledShiftTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledShiftTemplate? {
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

        func save(_ item: ScheduledShiftTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledShiftTemplate] {
            return inner.list()
        }
    }

    static func newCachedScheduledShiftTemplateStore(_ inner: MemoryScheduledShiftTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledShiftTemplateStore {
        return CachedScheduledShiftTemplateStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled shift templates. Empty fields match all.
    final class ScheduledShiftTemplateQuery {
        var channel: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledShiftTemplate) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledShiftTemplate]) -> [ScheduledShiftTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledShiftTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledShiftTemplates(_ store: any ScheduledShiftTemplateStore, query: ScheduledShiftTemplateQuery) -> [ScheduledShiftTemplate] {
        return query.apply(store.list())
    }
}
